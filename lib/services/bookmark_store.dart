import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import 'auth_service.dart';
import 'firestore_db.dart';

/// A bookmarked post's copy on this device.
class BookmarkCopy {
  final String uid;
  final Post post;
  /// Remote URL -> local file path, for every file downloaded so far.
  final Map<String, String> files;
  /// The podcast audio is over 50 MB, so it stays online-only.
  final bool audioTooLarge;
  /// The post was deleted or set inactive after it was bookmarked.
  final bool noLongerAvailable;
  final DateTime savedAt;

  const BookmarkCopy({
    required this.uid,
    required this.post,
    this.files = const {},
    this.audioTooLarge = false,
    this.noLongerAvailable = false,
    required this.savedAt,
  });

  String? fileFor(String url) => url.isEmpty ? null : files[url];
  String? get coverPath => fileFor(post.imageUrl);
  String? get videoPath => fileFor(post.videoUrl);
  String? get videoThumbnailPath => fileFor(post.videoThumbnailUrl);
  String? get audioPath => fileFor(post.audioUrl);
  List<String> get galleryPaths => [for (final u in post.mediaUrls) ?files[u]];

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'post': BookmarkStore.postToJson(post),
        'files': files,
        'audioTooLarge': audioTooLarge,
        'noLongerAvailable': noLongerAvailable,
        'savedAt': savedAt.millisecondsSinceEpoch,
      };

  factory BookmarkCopy.fromMap(Map<dynamic, dynamic> m) => BookmarkCopy(
        uid: m['uid'] as String? ?? '',
        post: BookmarkStore.postFromJson(Map<dynamic, dynamic>.from(m['post'] as Map)),
        files: {
          for (final e in ((m['files'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}',
        },
        audioTooLarge: m['audioTooLarge'] as bool? ?? false,
        noLongerAvailable: m['noLongerAvailable'] as bool? ?? false,
        savedAt: DateTime.fromMillisecondsSinceEpoch(m['savedAt'] as int? ?? 0),
      );

  BookmarkCopy copyWith({Post? post, Map<String, String>? files, bool? audioTooLarge, bool? noLongerAvailable}) =>
      BookmarkCopy(
        uid: uid,
        post: post ?? this.post,
        files: files ?? this.files,
        audioTooLarge: audioTooLarge ?? this.audioTooLarge,
        noLongerAvailable: noLongerAvailable ?? this.noLongerAvailable,
        savedAt: savedAt,
      );
}

enum BookmarkSyncResult { synced, offline }

class _TooLarge implements Exception {}

/// Bookmarks double as offline copies: bookmarking a post saves its text,
/// cover, gallery images, uploaded clip and podcast audio (under 50 MB) in
/// the app documents folder, so everything in Saved reads with no internet.
/// One Hive record per (account, post); each post's files live in their own
/// folder so removing a bookmark deletes them all at once.
class BookmarkStore {
  static const boxName = 'bookmark_copies';
  static const maxAudioBytes = 50 * 1024 * 1024;
  static final BookmarkStore instance = BookmarkStore._();
  BookmarkStore._();

  /// Post ids whose files are downloading right now (bookmark buttons show
  /// a small progress indicator for these).
  final ValueNotifier<Set<String>> downloading = ValueNotifier(const {});

  Future<Box> _box() => Hive.openBox(boxName);
  static String _key(String uid, String postId) => '$uid|$postId';

  Future<ValueListenable<Box>> listenable() async => (await _box()).listenable();

  List<BookmarkCopy> copiesIn(Box box, String uid) => [
        for (final v in box.values)
          if (v is Map && v['uid'] == uid) BookmarkCopy.fromMap(v),
      ];

  Future<BookmarkCopy?> copy(String uid, String postId) async {
    final v = (await _box()).get(_key(uid, postId));
    return v is Map ? BookmarkCopy.fromMap(v) : null;
  }

  // ── Post <-> plain JSON (Hive can't store Timestamps) ────────────────────

  static Map<String, dynamic> postToJson(Post p) {
    final m = Map<String, dynamic>.from(p.toMap());
    m['createdAt'] = p.createdAt.millisecondsSinceEpoch;
    m['id'] = p.id;
    return m;
  }

  static Post postFromJson(Map<dynamic, dynamic> j) {
    final m = Map<String, dynamic>.from(j);
    final created = m['createdAt'];
    m['createdAt'] = Timestamp.fromMillisecondsSinceEpoch(created is int ? created : 0);
    return Post.fromMap(m, m['id'] as String? ?? '');
  }

  // ── Files ────────────────────────────────────────────────────────────────

  /// `<app documents>/bookmark_files/<uid>/<postId>` — the folder Hive itself
  /// lives in, never the system cache (which Android may clear).
  Future<Directory> _postDir(String uid, String postId) async {
    final base = File((await _box()).path!).parent.path;
    final sep = Platform.pathSeparator;
    final dir = Directory('$base${sep}bookmark_files$sep$uid$sep$postId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _ext(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    final ext = dot < 0 ? '' : path.substring(dot);
    return ext.length > 6 ? '' : ext;
  }

  /// Streams [url] into [file]. Throws [_TooLarge] when [maxBytes] is set
  /// and exceeded (the partial file is deleted), or on any network error.
  Future<void> _download(String url, File file, {int? maxBytes}) async {
    final client = http.Client();
    try {
      final res = await client.send(http.Request('GET', Uri.parse(url))).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final total = res.contentLength;
      if (maxBytes != null && total != null && total > maxBytes) throw _TooLarge();
      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in res.stream) {
          received += chunk.length;
          if (maxBytes != null && received > maxBytes) throw _TooLarge();
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }
      if (total != null && total > 0 && received < total) throw const HttpException('Download incomplete');
    } catch (_) {
      if (await file.exists()) await file.delete();
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Every remote file a post needs offline, with a local file name each.
  static Map<String, String> _wantedFiles(Post p) => {
        if (p.imageUrl.isNotEmpty) p.imageUrl: 'cover${_ext(p.imageUrl)}',
        for (var i = 0; i < p.mediaUrls.length; i++)
          if (p.mediaUrls[i].isNotEmpty) p.mediaUrls[i]: 'gallery_$i${_ext(p.mediaUrls[i])}',
        if (p.hasClip) p.videoUrl: 'clip${_ext(p.videoUrl).isEmpty ? '.mp4' : _ext(p.videoUrl)}',
        if (p.hasClip && p.videoThumbnailUrl.isNotEmpty) p.videoThumbnailUrl: 'clip_thumb.jpg',
        if (p.audioUrl.isNotEmpty) p.audioUrl: 'audio${_ext(p.audioUrl)}',
      };

  /// Downloads whatever [copy] is still missing, deletes files for URLs the
  /// post no longer uses, and stores the result. A file that fails is simply
  /// left missing and retried at the next sync; the bookmark stays.
  Future<BookmarkCopy> _fillFiles(BookmarkCopy copy) async {
    if (kIsWeb) return copy;
    final wanted = _wantedFiles(copy.post);
    final files = Map<String, String>.from(copy.files);
    var audioTooLarge = copy.audioTooLarge && copy.post.audioUrl.isNotEmpty;
    // Files for URLs the post no longer uses (edited post): delete them.
    for (final url in files.keys.toList()) {
      if (!wanted.containsKey(url)) {
        final f = File(files.remove(url)!);
        if (await f.exists()) await f.delete();
      }
    }
    final dir = await _postDir(copy.uid, copy.post.id);
    for (final e in wanted.entries) {
      final existing = files[e.key];
      if (existing != null && await File(existing).exists()) continue;
      final isAudio = e.key == copy.post.audioUrl;
      if (isAudio && audioTooLarge) continue;
      final file = File('${dir.path}${Platform.pathSeparator}${e.value}');
      try {
        await _download(e.key, file, maxBytes: isAudio ? maxAudioBytes : null);
        files[e.key] = file.path;
      } on _TooLarge {
        audioTooLarge = true;
      } catch (err) {
        debugPrint('Bookmark file download failed (${e.value}): $err');
      }
    }
    final updated = copy.copyWith(files: files, audioTooLarge: audioTooLarge);
    await (await _box()).put(_key(copy.uid, copy.post.id), updated.toMap());
    return updated;
  }

  Future<void> _deleteFiles(String uid, String postId) async {
    if (kIsWeb) return;
    try {
      final dir = await _postDir(uid, postId);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      debugPrint('Bookmark files delete failed: $e');
    }
  }

  // ── Bookmark / unbookmark ────────────────────────────────────────────────

  /// Saves the text right away (so Saved shows it at once), then downloads
  /// its files with [downloading] marking progress.
  Future<void> save(String uid, Post post) async {
    final old = await copy(uid, post.id);
    final base = BookmarkCopy(
      uid: uid,
      post: post,
      files: old?.files ?? const {},
      audioTooLarge: old?.audioTooLarge ?? false,
      savedAt: old?.savedAt ?? DateTime.now(),
    );
    await (await _box()).put(_key(uid, post.id), base.toMap());
    downloading.value = {...downloading.value, post.id};
    try {
      await _fillFiles(base);
    } finally {
      downloading.value = {...downloading.value}..remove(post.id);
    }
  }

  /// Unbookmark: deletes the copy and every file it downloaded.
  Future<void> remove(String uid, String postId) async {
    await _deleteFiles(uid, postId);
    await (await _box()).delete(_key(uid, postId));
  }

  // ── Sync ─────────────────────────────────────────────────────────────────

  static bool _sameContent(Post a, Post b) =>
      jsonEncode(postToJson(a)) == jsonEncode(postToJson(b));

  /// Sync, run on app start (and each sign-in) and whenever Saved opens.
  /// Posts have no updatedAt, so a change is detected by comparing the
  /// stored fields with the server's. For every bookmarked id:
  ///  - the server can't be reached -> stop, keep every copy as it is and
  ///    report [BookmarkSyncResult.offline];
  ///  - the post was deleted or set inactive -> keep the copy, mark it
  ///    "No longer available online";
  ///  - no local copy yet (bookmarked on another device, or a reinstall) ->
  ///    download it;
  ///  - the post changed -> store the new fields and download only files
  ///    whose URLs changed (old ones are deleted);
  ///  - otherwise -> just retry any files that failed last time.
  /// Copies whose ids are no longer bookmarked (removed on another device)
  /// are deleted with their files.
  Future<BookmarkSyncResult> sync(String uid, List<String> bookmarkedIds) async {
    final box = await _box();
    final local = {for (final c in copiesIn(box, uid)) c.post.id: c};
    try {
      for (final id in bookmarkedIds) {
        final doc = await FirestoreDb.instance
            .collection('posts')
            .doc(id)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 10));
        final fresh = doc.exists ? Post.fromMap(doc.data()!, doc.id) : null;
        final existing = local[id];
        if (fresh == null || !fresh.isActive) {
          if (existing != null && !existing.noLongerAvailable) {
            await box.put(_key(uid, id), existing.copyWith(noLongerAvailable: true).toMap());
          }
          continue;
        }
        if (existing == null) {
          await save(uid, fresh);
          continue;
        }
        final changed = !_sameContent(existing.post, fresh);
        final updated = existing.copyWith(
          files: _remapMigrated(existing.files, fresh),
          post: changed ? fresh : existing.post,
          noLongerAvailable: false,
          audioTooLarge: changed && existing.post.audioUrl != fresh.audioUrl ? false : null,
        );
        downloading.value = {...downloading.value, id};
        try {
          await _fillFiles(updated);
        } finally {
          downloading.value = {...downloading.value}..remove(id);
        }
      }
      for (final id in local.keys) {
        if (!bookmarkedIds.contains(id)) await remove(uid, id);
      }
      return BookmarkSyncResult.synced;
    } on TimeoutException {
      return BookmarkSyncResult.offline;
    } on FirebaseException catch (e) {
      debugPrint('Bookmark sync stopped: ${e.code}');
      return BookmarkSyncResult.offline;
    } on SocketException {
      return BookmarkSyncResult.offline;
    }
  }

  /// Files moved over from the old offline downloads are stored under
  /// placeholder keys until the real post is known; attach them to its URLs
  /// so they are kept instead of downloaded again.
  static Map<String, String> _remapMigrated(Map<String, String> files, Post p) {
    final out = Map<String, String>.from(files);
    void attach(String key, String url) {
      final path = out.remove(key);
      if (path != null && url.isNotEmpty) out[url] = path;
    }

    attach('migrated://cover', p.imageUrl);
    attach('migrated://clip', p.videoUrl);
    attach('migrated://thumb', p.videoThumbnailUrl);
    return out;
  }

  // ── Start-up: migration + first sync ─────────────────────────────────────

  bool _started = false;
  String? _syncedUid;

  /// Called once at app start. Runs the one-time migration and a sync for
  /// the signed-in user, and again whenever a different user signs in.
  void start() {
    if (_started) return;
    _started = true;
    void onUser() {
      final user = AuthService.instance.currentUser;
      if (user == null || user.uid == _syncedUid) return;
      _syncedUid = user.uid;
      unawaited(_migrateAndSync(user));
    }

    AuthService.instance.userNotifier.addListener(onUser);
    onUser();
  }

  Future<void> _migrateAndSync(UserData user) async {
    try {
      final ids = await _migrateOldDownloads(user);
      final current = AuthService.instance.currentUser;
      await sync(user.uid, {...?current?.bookmarkedPostIds, ...ids}.toList());
    } catch (e) {
      debugPrint('Bookmark start-up sync failed: $e');
    }
  }

  static const _migrationFlag = 'offline_downloads_migrated_to_bookmarks';
  static const _oldBoxName = 'offline_posts';

  /// One-time migration from the removed "Save for Offline" feature, run on
  /// the first launch after the update where someone is signed in:
  ///  1. every old offline entry's post is added to the signed-in user's
  ///     bookmarkedPostIds (one Firestore update);
  ///  2. its text becomes a bookmark copy right away, its downloaded clip and
  ///     thumbnail files are MOVED into the bookmark folder, and its cover
  ///     (stored as bytes) is written out as a file, so nothing a fan saved
  ///     is lost even before the next sync fills in the full post;
  ///  3. the old Hive box and the old offline_videos folder are deleted and
  ///     a local flag is set so this never runs again.
  /// With nobody signed in it does nothing, keeping the old files until the
  /// next sign-in. Returns the ids it moved.
  Future<List<String>> _migrateOldDownloads(UserData user) async {
    if (kIsWeb) return const [];
    final prefs = await Hive.openBox('app_prefs');
    if (prefs.get(_migrationFlag) == true) return const [];
    final old = await Hive.openBox(_oldBoxName);
    final oldDir = Directory('${File(old.path!).parent.path}${Platform.pathSeparator}offline_videos');
    final moved = <String>[];
    for (final raw in old.values) {
      if (raw is! Map) continue;
      final m = Map<dynamic, dynamic>.from(raw);
      final id = m['id'] as String?;
      if (id == null || id.isEmpty) continue;
      final dir = await _postDir(user.uid, id);
      final sep = Platform.pathSeparator;
      final files = <String, String>{};
      Future<String?> move(String? from, String name) async {
        if (from == null) return null;
        final f = File(from);
        if (!await f.exists()) return null;
        final target = '${dir.path}$sep$name';
        try {
          return (await f.rename(target)).path;
        } catch (_) {
          await f.copy(target);
          await f.delete();
          return target;
        }
      }

      final video = await move(m['videoPath'] as String?, 'clip.mp4');
      final thumb = await move(m['videoThumbnailPath'] as String?, 'clip_thumb.jpg');
      final bytes = m['imageBytes'];
      String? cover;
      if (bytes is Uint8List) {
        cover = '${dir.path}${sep}cover';
        await File(cover).writeAsBytes(bytes, flush: true);
      }
      // The old record kept only a few fields; the next sync fills in the
      // rest and maps these files to the post's real URLs.
      final placeholder = Post(
        id: id,
        title: m['title'] as String? ?? '',
        content: m['content'] as String? ?? '',
        category: m['category'] as String? ?? '',
        contentType: m['contentType'] as String? ?? 'News',
        createdAt: DateTime.tryParse(m['savedAt'] as String? ?? '') ?? DateTime.now(),
        imageUrl: cover == null ? '' : 'migrated://cover',
        videoUrl: video == null ? '' : 'migrated://clip',
        videoThumbnailUrl: thumb == null ? '' : 'migrated://thumb',
        youtubeUrl: (m['hasYoutubeVideo'] as bool? ?? false) ? 'migrated://youtube' : null,
      );
      if (cover != null) files['migrated://cover'] = cover;
      if (video != null) files['migrated://clip'] = video;
      if (thumb != null) files['migrated://thumb'] = thumb;
      await (await _box()).put(
        _key(user.uid, id),
        BookmarkCopy(uid: user.uid, post: placeholder, files: files, savedAt: DateTime.now()).toMap(),
      );
      moved.add(id);
    }
    if (moved.isNotEmpty) {
      await FirestoreDb.instance.collection('users').doc(user.uid).update({
        'bookmarkedPostIds': FieldValue.arrayUnion(moved),
      });
      final current = AuthService.instance.currentUser;
      if (current != null && current.uid == user.uid) {
        AuthService.instance.userNotifier.value = current.copyWith(
          bookmarkedPostIds: {...current.bookmarkedPostIds, ...moved}.toList(),
        );
      }
    }
    await old.deleteFromDisk();
    if (await oldDir.exists()) await oldDir.delete(recursive: true);
    await prefs.put(_migrationFlag, true);
    return moved;
  }
}
