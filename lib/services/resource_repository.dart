import '../models/app_category.dart';
import '../models/creator.dart';
import '../models/fandom.dart';
import '../models/post.dart';
import 'category_service.dart';
import 'creator_service.dart';
import 'fandom_service.dart';
import 'firestore_db.dart';

class ResourceData {
  final List<Post> posts;
  final List<Creator> creators;
  final List<Fandom> fandoms;
  final List<AppCategory> categories;

  const ResourceData({
    required this.posts,
    required this.creators,
    required this.fandoms,
    required this.categories,
  });
}

/// Everything the Resources screen filters on the device.
///
/// Scaling note: this loads every active post and filters/searches in
/// memory, which is fine up to roughly 1,500 posts. Past that, replace this
/// implementation with an external search index (for example the Algolia
/// or Typesense Firebase extension) behind this same interface — the
/// controller and screens don't change.
abstract class ResourceRepository {
  Future<ResourceData> loadAll();
}

class FirestoreResourceRepository implements ResourceRepository {
  const FirestoreResourceRepository();

  @override
  Future<ResourceData> loadAll() async {
    final results = await Future.wait<Object>([
      // No status filter in the query: it would drop legacy posts without a
      // status field, which Post.fromMap treats as active.
      FirestoreDb.instance.collection('posts').get().then((s) => [
            for (final d in s.docs) Post.fromMap(d.data(), d.id),
          ].where((p) => p.isActive).toList()),
      CreatorService.instance.getAll(),
      FandomService.instance.getAllActive(),
      CategoryService.instance.fetchCategories(),
    ]);
    return ResourceData(
      posts: results[0] as List<Post>,
      creators: results[1] as List<Creator>,
      fandoms: results[2] as List<Fandom>,
      categories: [
        for (final c in results[3] as List<AppCategory>)
          if (c.isActive) c,
      ]..sort((a, b) => a.order.compareTo(b.order)),
    );
  }
}
