import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
      watchActivePosts().map(
        (posts) => posts.where((p) => p.contentType == contentType).toList(),
      );

  /// Returns the currently flagged "Today's Fandom" post, or null if none.
  Stream<Post?> watchFandomOfTheDay() => watchActivePosts().map((posts) {
    for (final p in posts) {
      if (p.isFandomOfTheDay) return p;
    }
    return null;
  });

  static String todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

 
  static final Set<String> _viewedThisSession = {};

  @visibleForTesting
  static void resetSessionViews() => _viewedThisSession.clear();

  Future<void> recordView(String postId) async {
    if (!_viewedThisSession.add(postId)) return;
    final ref = FirestoreDb.instance.collection('posts').doc(postId);
    final today = todayKey();
    try {
      for (var attempt = 1; ; attempt++) {
        try {
          await FirestoreDb.instance.runTransaction((tx) async {
            final snap = await tx.get(ref);
            if (!snap.exists) return;
            final sameDay = snap.data()!['todayViewDate'] == today;
            tx.update(ref, {
              'todayViewCount': sameDay ? FieldValue.increment(1) : 1,
              'todayViewDate': today,
              'viewCount': FieldValue.increment(1),
            });
          });
          return;
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied' || attempt >= 3) rethrow;
        }
      }
    } catch (_) {
      _viewedThisSession.remove(postId);
      rethrow;
    }
  }


  Stream<List<Post>> watchViewedToday(String today) => FirestoreDb.instance
      .collection('posts')

      .where('todayViewDate', isEqualTo: today)
      .snapshots()

      .map((s) => s.docs.map((d) => Post.fromMap(d.data(), d.id)).toList());

  Stream<List<Post>> watchPostsInFandoms(List<String> fandomIds) =>
      FirestoreDb.instance
          .collection('posts')
          .where('fandomId', whereIn: fandomIds)
          .snapshots()
          .map((s) => s.docs.map((d) => Post.fromMap(d.data(), d.id)).toList());


  Stream<List<Post>> watchPostsByCreator(String creatorId) => FirestoreDb.instance
      .collection('posts')
      .where('creatorId', isEqualTo: creatorId)

      .snapshots()

      .map((s) => s.docs

          .map((d) => Post.fromMap(d.data(), d.id))
          .where((p) => p.isActive)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Stream<List<Post>> watchPostsByFandom(String fandomId) => FirestoreDb.instance
      .collection('posts')
      .where('fandomId', isEqualTo: fandomId)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => Post.fromMap(d.data(), d.id)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );



  Future<String> savePost(Post post, {required bool isNew}) async {
    final db = FirestoreDb.instance;
    final posts = db.collection('posts');
    final ref = isNew ? posts.doc() : posts.doc(post.id);
    final batch = db.batch();
    final data = post.toMap();
    if (isNew) {
      batch.set(ref, data);
    } else {
      if (!post.hasVideo) data['youtubeUrl'] = FieldValue.delete();
      batch.update(ref, data);
    }
    if (post.isFandomOfTheDay) {
      final flagged =
          await posts.where('isFandomOfTheDay', isEqualTo: true).get();
      for (final doc in flagged.docs) {
        if (doc.id == ref.id) continue;
        batch.update(doc.reference, {'isFandomOfTheDay': false});
      }
    }
    await batch.commit();
    return ref.id;
  }

  /// Adds a post and returns its new document id.
  Future<String> addPost(Post post) async {
    final ref = await FirestoreDb.instance
        .collection('posts')
        .add(post.toMap());
    return ref.id;
  }

  Future<void> updatePost(Post post) {
    final data = post.toMap();

    if (!post.hasVideo) {


      data['youtubeUrl'] = FieldValue.delete();
    }
    return FirestoreDb.instance.collection('posts').doc(post.id).update(data);
  }

  Future<void> deletePost(String id) =>
      FirestoreDb.instance.collection('posts').doc(id).delete();



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
    batch.update(FirestoreDb.instance.collection('posts').doc(postId), {
      'isFandomOfTheDay': true,
    });
    await batch.commit();
  }

  Future<void> clearFandomOfTheDay(String postId) => FirestoreDb.instance
      .collection('posts')
      .doc(postId)
      .update({'isFandomOfTheDay': false});
}
