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

  /// Today's date as stored in `todayViewDate` ("yyyy-MM-dd", device-local).
  static String todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Counts one view of [postId] for today (Trending Today).
  ///
  /// This must be a transaction, not a plain update: the new value depends
  /// on what's stored. If the stored day is today we add 1; if it's any
  /// other day, yesterday's count is stale and we restart at 1 with today's
  /// date. Done as a separate read then write, two fans viewing at the same
  /// moment could both read "yesterday", both write count = 1, and lose a
  /// view — or one could increment a count the other just reset. A
  /// transaction makes read → compare → reset-or-increment atomic: if the
  /// document changes between our read and our write, Firestore re-runs the
  /// whole function against the fresh value.
  ///
  /// (FieldValue.increment alone can't express this: it can't reset to 1 on
  /// a new day.)
  ///
  /// Two details make this hold up under real contention:
  /// - Same day, the transaction writes FieldValue.increment(1) rather than
  ///   a computed number, so the server adds 1 to whatever is stored at
  ///   commit time. A computed "stale + 1" would be rejected by the security
  ///   rule (which requires exactly stored + 1) as PERMISSION_DENIED, and
  ///   that error is not retried by the SDK — the view would be lost.
  /// - At a day rollover two fans can both read "yesterday" and both try to
  ///   reset to 1; the rule rejects the second reset (the date already
  ///   matches), so we retry: the retry reads today's date and increments.
  Future<void> recordView(String postId) async {
    final ref = FirestoreDb.instance.collection('posts').doc(postId);
    final today = todayKey();
    for (var attempt = 1;; attempt++) {
      try {
        await FirestoreDb.instance.runTransaction((tx) async {
          final snap = await tx.get(ref);
          if (!snap.exists) return;
          final sameDay = snap.data()!['todayViewDate'] == today;
          tx.update(ref, {
            'todayViewCount': sameDay ? FieldValue.increment(1) : 1,
            'todayViewDate': today,
          });
        });
        return;
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied' || attempt >= 3) rethrow;
      }
    }
  }

  /// Posts viewed today (single-field equality — no composite index). The
  /// caller picks the top one; see TrendingService.
  Stream<List<Post>> watchViewedToday(String today) => FirestoreDb.instance
      .collection('posts')
      .where('todayViewDate', isEqualTo: today)
      .snapshots()
      .map((s) => s.docs.map((d) => Post.fromMap(d.data(), d.id)).toList());

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
