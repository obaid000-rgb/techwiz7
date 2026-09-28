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

  /// Valid category keys: lowercase letters, digits and underscores.
  static final keyPattern = RegExp(r'^[a-z0-9_]+$');

  /// Creates categories/{key} only if no category already uses that key.
  /// Returns false (and writes nothing) when the key is taken, so an
  /// existing category can never be silently overwritten.
  Future<bool> addCategory(AppCategory cat) =>
      FirestoreDb.instance.runTransaction((tx) async {
        final ref = FirestoreDb.instance.collection('categories').doc(cat.key);
        if ((await tx.get(ref)).exists) return false;
        tx.set(ref, cat.toMap());
        return true;
      });

  Future<void> updateCategory(AppCategory cat) async {
    final db = FirestoreDb.instance;
    final batch = db.batch();
    batch.update(db.collection('categories').doc(cat.id), cat.toMap());
    // Category rename: copy the new name into the denormalized categoryName
    // of every fandom in this category, committed in the same batch as the
    // category itself so the two can never disagree.
    final fandoms = await db
        .collection('fandoms')
        .where('categoryId', isEqualTo: cat.key)
        .get();
    for (final d in fandoms.docs) {
      if (d.data()['categoryName'] != cat.name) {
        batch.update(d.reference, {'categoryName': cat.name});
      }
    }
    await batch.commit();
  }

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
          .where('categoryId', isEqualTo: key)
          .get(),
    ]);
    return {
      'posts': results[0].docs.length,
      'merchandise': results[1].docs.length,
      'fandoms': results[2].docs.where((d) => d.data()['isActive'] != false).length,
    };
  }

  /// Soft-deletes (isActive: false) every fandom in category [key], so the
  /// category can be deleted; the fandoms stay restorable from Fandoms.
  Future<void> deactivateFandomsIn(String key) async {
    final snap = await FirestoreDb.instance
        .collection('fandoms')
        .where('categoryId', isEqualTo: key)
        .get();
    final batch = FirestoreDb.instance.batch();
    for (final d in snap.docs) {
      if (d.data()['isActive'] != false) batch.update(d.reference, {'isActive': false});
    }
    await batch.commit();
  }
}
