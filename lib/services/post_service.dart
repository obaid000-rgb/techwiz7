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

  Future<void> addPost(Post post) =>
      FirestoreDb.instance.collection('posts').add(post.toMap());

  Future<void> updatePost(Post post) => FirestoreDb.instance
      .collection('posts')
      .doc(post.id)
      .update(post.toMap());

  Future<void> deletePost(String id) =>
      FirestoreDb.instance.collection('posts').doc(id).delete();
}
