import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/event_item.dart';
import 'event_service.dart';

/// One saved event's offline copy.
class SavedEventEntry {
  final String uid;
  final EventItem event;
  /// Cover image downloaded to a local file (null when there's no cover,
  /// the download failed, or on web).
  final String? imagePath;
  /// Web has no file system: the cover is kept as bytes in the record.
  final Uint8List? imageBytes;
  final DateTime savedAt;
  /// The event was unpublished or deleted after the fan saved it. The copy
  /// is kept so the fan can still see what it was.
  final bool noLongerListed;

  const SavedEventEntry({
    required this.uid,
    required this.event,
    this.imagePath,
    this.imageBytes,
    required this.savedAt,
    this.noLongerListed = false,
  });

  bool get hasImage => imagePath != null || imageBytes != null;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'event': event.toJson(),
        'imagePath': imagePath,
        'imageBytes': imageBytes,
        'savedAt': savedAt.millisecondsSinceEpoch,
        'noLongerListed': noLongerListed,
      };

  factory SavedEventEntry.fromMap(Map<dynamic, dynamic> m) => SavedEventEntry(
        uid: m['uid'] as String? ?? '',
        event: EventItem.fromJson(Map<dynamic, dynamic>.from(m['event'] as Map)),
        imagePath: m['imagePath'] as String?,
        imageBytes: m['imageBytes'] is Uint8List ? m['imageBytes'] as Uint8List : null,
        savedAt: DateTime.fromMillisecondsSinceEpoch(m['savedAt'] as int? ?? 0),
        noLongerListed: m['noLongerListed'] as bool? ?? false,
      );

  SavedEventEntry copyWith({
    EventItem? event,
    String? imagePath,
    Uint8List? imageBytes,
    bool clearImage = false,
    bool? noLongerListed,
  }) =>
      SavedEventEntry(
        uid: uid,
        event: event ?? this.event,
        imagePath: clearImage ? null : (imagePath ?? this.imagePath),
        imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
        savedAt: savedAt,
        noLongerListed: noLongerListed ?? this.noLongerListed,
      );
}

enum AgendaSyncResult { synced, offline }

/// Offline copies of the events a fan saved to My Agenda (SRS: "event
/// agendas must support offline access via local storage syncing").
/// One Hive record per (account, event) holds every event field, the
/// agenda and updatedAt; the cover image is downloaded to a local file,
/// like offline posts download theirs. My Agenda reads only from here.
class SavedEventStore {
  static const boxName = 'saved_events';
  static final SavedEventStore instance = SavedEventStore._();
  SavedEventStore._();

  Future<Box> _box() => Hive.openBox(boxName);

  static String _key(String uid, String eventId) => '$uid|$eventId';

  Future<ValueListenable<Box>> listenable() async => (await _box()).listenable();

  Future<List<SavedEventEntry>> entriesFor(String uid) async {
    final box = await _box();
    return [
      for (final v in box.values)
        if (v is Map && v['uid'] == uid) SavedEventEntry.fromMap(v),
    ];
  }

  Future<SavedEventEntry?> entry(String uid, String eventId) async {
    final v = (await _box()).get(_key(uid, eventId));
    return v is Map ? SavedEventEntry.fromMap(v) : null;
  }

  /// Where cover images live: a folder beside the Hive files (the app's
  /// documents directory), so no extra plugin is needed.
  Future<Directory?> _imageDir() async {
    if (kIsWeb) return null;
    final path = (await _box()).path;
    if (path == null) return null;
    final dir = Directory('${File(path).parent.path}${Platform.pathSeparator}saved_event_images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Downloads [url]; returns (file path, bytes-for-web). Failures return
  /// nulls so the text copy is still saved without its image.
  Future<(String?, Uint8List?)> _download(String uid, String eventId, String url) async {
    if (url.isEmpty) return (null, null);
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return (null, null);
      final dir = await _imageDir();
      if (dir == null) return (null, res.bodyBytes);
      final file = File('${dir.path}${Platform.pathSeparator}${uid}_$eventId.img');
      await file.writeAsBytes(res.bodyBytes, flush: true);
      return (file.path, null);
    } catch (e) {
      debugPrint('Saved event image download failed: $e');
      return (null, null);
    }
  }

  Future<void> _deleteImage(String? path) async {
    if (path == null || kIsWeb) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('Saved event image delete failed: $e');
    }
  }

  /// Stores (or replaces) the full offline copy of [event] for [uid].
  Future<void> put(String uid, EventItem event) async {
    final old = await entry(uid, event.id);
    var (path, bytes) = await _download(uid, event.id, event.imageUrl);
    final sameCover = old != null && old.event.imageUrl == event.imageUrl;
    if (path == null && bytes == null && sameCover) {
      // Download failed but the cover didn't change: keep the old image.
      path = old.imagePath;
      bytes = old.imageBytes;
    } else if (old?.imagePath != null && old!.imagePath != path) {
      await _deleteImage(old.imagePath);
    }
    await (await _box()).put(
      _key(uid, event.id),
      SavedEventEntry(
        uid: uid,
        event: event,
        imagePath: path,
        imageBytes: bytes,
        savedAt: old?.savedAt ?? DateTime.now(),
      ).toMap(),
    );
  }

  /// Unsave: deletes the copy and its image file.
  Future<void> remove(String uid, String eventId) async {
    final old = await entry(uid, eventId);
    await _deleteImage(old?.imagePath);
    await (await _box()).delete(_key(uid, eventId));
  }

  /// Sync, run when My Agenda opens. For each saved event it asks the
  /// server (never the local cache):
  ///  - no internet (timeout / unavailable) -> stop, keep every copy as is,
  ///    and report [AgendaSyncResult.offline];
  ///  - event deleted or unpublished -> keep the copy, mark it
  ///    "no longer listed" (the fan still sees what it was);
  ///  - event's updatedAt newer than the copy's -> refresh the copy and
  ///    re-download its image (an admin edited it, e.g. the agenda);
  ///  - otherwise only the interested count is refreshed.
  /// It also brings the copies in line with [savedIds] (the account's saved
  /// list): events saved on another device get a copy, and copies of events
  /// unsaved elsewhere are removed.
  Future<AgendaSyncResult> sync(String uid, List<String> savedIds) async {
    final entries = {for (final e in await entriesFor(uid)) e.event.id: e};
    final box = await _box();
    try {
      for (final id in savedIds) {
        final fresh = await EventService.instance.fetchFromServer(id);
        final local = entries[id];
        if (fresh == null || !fresh.isPublished) {
          if (local != null && !local.noLongerListed) {
            await box.put(_key(uid, id), local.copyWith(noLongerListed: true).toMap());
          }
          continue;
        }
        if (local == null) {
          await put(uid, fresh);
          continue;
        }
        final localUpdated = local.event.updatedAt;
        final newer = fresh.updatedAt != null &&
            (localUpdated == null || fresh.updatedAt!.isAfter(localUpdated));
        if (newer) {
          await put(uid, fresh);
        } else if (local.noLongerListed ||
            local.event.interestedCount != fresh.interestedCount) {
          await box.put(
            _key(uid, id),
            local
                .copyWith(
                  event: local.event.copyWith(interestedCount: fresh.interestedCount),
                  noLongerListed: false,
                )
                .toMap(),
          );
        }
      }
      for (final id in entries.keys) {
        if (!savedIds.contains(id)) await remove(uid, id);
      }
      return AgendaSyncResult.synced;
    } on TimeoutException {
      return AgendaSyncResult.offline;
    } on FirebaseException catch (e) {
      debugPrint('Agenda sync stopped: ${e.code}');
      return AgendaSyncResult.offline;
    } on SocketException {
      return AgendaSyncResult.offline;
    }
  }
}
