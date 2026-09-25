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

  /// Returns counts: posts, merchandise, fandoms using this category key.
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
