import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../models/tag.dart';
import '../utils/tag_utils.dart';
import 'firestore_db.dart';

class TagService {
  static final TagService instance = TagService._();
  TagService._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreDb.instance.collection('tags');

  Stream<List<Tag>> watchAll() => _col
      .snapshots()
      .map((s) => s.docs.map((d) => Tag.fromMap(d.data(), d.id)).toList());

  Future<List<Tag>> getAll() async =>
      (await _col.get()).docs.map((d) => Tag.fromMap(d.data(), d.id)).toList();

  Future<void> setPinned(String id, bool pinned) =>
      _col.doc(id).update({'isPinned': pinned});

  Future<void> delete(String id) => _col.doc(id).delete();

  /// Post counts per tag slug, computed on the device from [posts]
  /// (counts are never stored).
  static Map<String, int> countsFrom(Iterable<Post> posts) {
    final counts = <String, int>{};
    for (final p in posts) {
      for (final t in normalizeTags(p.tags)) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Tags from [tags] (slug → display name) that have no tags/{slug}
  /// document yet — the ones a post save must create.
  Future<Map<String, String>> missing(Map<String, String> tags) async {
    if (tags.isEmpty) return const {};
    final existing = (await getAll()).map((t) => t.id).toSet();
    return {
      for (final e in tags.entries)
        if (!existing.contains(e.key)) e.key: e.value,
    };
  }
}
