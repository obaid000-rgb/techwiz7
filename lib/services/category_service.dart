import '../models/app_category.dart';
import 'firestore_db.dart';

class CategoryService {
  static final CategoryService instance = CategoryService._();
  CategoryService._();

  Stream<List<AppCategory>> watchCategories() => FirestoreDb.instance
      .collection('categories')
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs
          .map((d) => AppCategory.fromMap(d.data(), d.id))
          .toList());

  Stream<List<AppCategory>> watchActiveCategories() =>
      watchCategories().map((cats) => cats.where((c) => c.isActive).toList());

  Future<List<AppCategory>> fetchCategories() async {
    final s = await FirestoreDb.instance
        .collection('categories')
        .orderBy('order')
        .get();
    return s.docs.map((d) => AppCategory.fromMap(d.data(), d.id)).toList();
  }

  Future<void> addCategory(AppCategory cat) => FirestoreDb.instance
      .collection('categories')
      .doc(cat.key)
      .set(cat.toMap());

  Future<void> updateCategory(AppCategory cat) => FirestoreDb.instance
      .collection('categories')
      .doc(cat.id)
      .update(cat.toMap());

  Future<void> deleteCategory(String id) =>
      FirestoreDb.instance.collection('categories').doc(id).delete();

  /// Persists a new display order for a full, freshly-ordered list of
  /// categories (index in the list becomes its `order` value).
  Future<void> reorderCategories(List<AppCategory> orderedCats) async {
    final batch = FirestoreDb.instance.batch();
    for (var i = 0; i < orderedCats.length; i++) {
      final cat = orderedCats[i];
      if (cat.order == i) continue;
      batch.update(
        FirestoreDb.instance.collection('categories').doc(cat.id),
        {'order': i},
      );
    }
    await batch.commit();
  }

  /// True if another category already uses this name (case-insensitive).
  /// Pass [excludeId] when renaming an existing category so it doesn't
  /// collide with itself.
  Future<bool> nameExists(String name, {String? excludeId}) async {
    final s = await FirestoreDb.instance.collection('categories').get();
    final normalized = name.trim().toLowerCase();
    return s.docs.any((d) {
      if (excludeId != null && d.id == excludeId) return false;
      final existingName = (d.data()['name'] as String? ?? '').toLowerCase();
      return existingName == normalized;
    });
  }

  /// Live count of Posts referencing this category's key.
  Stream<int> watchPostCount(String categoryKey) => FirestoreDb.instance
      .collection('posts')
      .where('category', isEqualTo: categoryKey)
      .snapshots()
      .map((s) => s.docs.length);

  /// Returns usage counts across posts, merchandise, and fandoms for a given key.
  Future<Map<String, int>> checkUsage(String key) async {
    final results = await Future.wait([
      FirestoreDb.instance
          .collection('posts')
          .where('category', isEqualTo: key)
          .limit(1)
          .get(),
      FirestoreDb.instance
          .collection('merchandise')
          .where('category', isEqualTo: key)
          .limit(1)
          .get(),
      FirestoreDb.instance
          .collection('fandoms')
          .where('category', isEqualTo: key)
          .limit(1)
          .get(),
    ]);
    return {
      'posts': results[0].docs.length,
      'merchandise': results[1].docs.length,
      'fandoms': results[2].docs.length,
    };
  }
}
