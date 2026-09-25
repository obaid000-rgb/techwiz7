import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import 'firestore_db.dart';

class PostService {
  static final PostService instance = PostService._();
  PostService._();

  Stream<List<Post>> watchPosts() => FirestoreDb.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Post.fromMap(d.data(), d.id)).toList());

  /// Same as [watchPosts] but only Active posts, still newest-first.
  Stream<List<Post>> watchActivePosts() =>
      watchPosts().map((posts) => posts.where((p) => p.isActive).toList());

  Stream<List<Post>> watchPostsByContentType(String contentType) =>
      watchActivePosts()
          .map((posts) => posts.where((p) => p.contentType == contentType).toList());

  /// Returns the currently flagged "Today's Fandom" post, or null if none.
  Stream<Post?> watchFandomOfTheDay() => watchActivePosts().map(
        (posts) {
          for (final p in posts) {
            if (p.isFandomOfTheDay) return p;
          }
          return null;
        },
      );

  /// Adds a post and returns its new document id.
  Future<String> addPost(Post post) async {
    final ref =
        await FirestoreDb.instance.collection('posts').add(post.toMap());
    return ref.id;
  }

  Future<void> updatePost(Post post) {
    final data = post.toMap();
    if (!post.hasVideo) {
      // toMap() omits youtubeUrl when null, which would leave a stale
      // value in Firestore on a plain update() — delete it explicitly.
      data['youtubeUrl'] = FieldValue.delete();
    }
    return FirestoreDb.instance.collection('posts').doc(post.id).update(data);
  }

  Future<void> deletePost(String id) =>
      FirestoreDb.instance.collection('posts').doc(id).delete();

  /// Flags [postId] as Today's Fandom and unflags every other post,
  /// so exactly zero or one post ever has the flag set.
  Future<void> setFandomOfTheDay(String postId) async {
    final currentlyFlagged = await FirestoreDb.instance
        .collection('posts')
        .where('isFandomOfTheDay', isEqualTo: true)
        .get();
    final batch = FirestoreDb.instance.batch();
    for (final doc in currentlyFlagged.docs) {
      if (doc.id == postId) continue;
      batch.update(doc.reference, {'isFandomOfTheDay': false});
    }
    batch.update(
      FirestoreDb.instance.collection('posts').doc(postId),
      {'isFandomOfTheDay': true},
    );
    await batch.commit();
  }

  Future<void> clearFandomOfTheDay(String postId) => FirestoreDb.instance
      .collection('posts')
      .doc(postId)
      .update({'isFandomOfTheDay': false});
}
