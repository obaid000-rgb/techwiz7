import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/offline_saved_post.dart';
import '../models/post.dart';

/// Local-only storage for "Save for Offline" — distinct from the live
/// Firestore-backed Bookmark feature. Everything (text, metadata, and the
/// image as raw bytes) lives in one Hive record per post, so removing a
/// save is a single atomic delete with nothing left to orphan.
class OfflineService {
  static const boxName = 'offline_posts';
  static final OfflineService instance = OfflineService._();
  OfflineService._();

  Future<Box> _box() => Hive.openBox(boxName);

  Future<bool> isSaved(String postId) async {
    final box = await _box();
    return box.containsKey(postId);
  }

  /// A repaint-on-change listenable for the box, for live UI updates.
  Future<ValueListenable<Box>> listenable() async {
    final box = await _box();
    return box.listenable();
  }

  Future<void> saveOffline(Post post) async {
    List<int>? imageBytes;
    if (post.imageUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(post.imageUrl));
        if (res.statusCode == 200) imageBytes = res.bodyBytes;
      } catch (_) {
        // Image download failed — still save the text so a flaky network
        // mid-download doesn't lose the whole save; the image just won't
        // be available offline for this entry.
      }
    }
    final entry = OfflineSavedPost(
      id: post.id,
      title: post.title,
      content: post.content,
      category: post.category,
      contentType: post.contentType,
      savedAt: DateTime.now(),
      imageBytes: imageBytes == null ? null : Uint8List.fromList(imageBytes),
    );
    final box = await _box();
    await box.put(post.id, entry.toMap());
  }

  Future<void> removeOffline(String postId) async {
    final box = await _box();
    await box.delete(postId);
  }

  Future<List<OfflineSavedPost>> getAll() async {
    final box = await _box();
    return box.values
        .map((v) => OfflineSavedPost.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }
}
