import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'firestore_db.dart';

class UserService {
  static final UserService instance = UserService._();
  UserService._();

  Stream<List<UserData>> watchUsers() => FirestoreDb.instance
      .collection('users')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => UserData.fromMap(d.data(), d.id)).toList());

  Future<void> updateUser(UserData user) => FirestoreDb.instance
      .collection('users')
      .doc(user.uid)
      .update(user.toMap());

  /// Adds/removes one product on the user's wishlist. Writes only that
  /// array entry (arrayUnion/arrayRemove) plus that product's price baseline
  /// (`wishlistPrices.<id>`, via a field path), in one update — so it can't
  /// overwrite anything else on the user document with stale values.
  /// [price] is the product's price at the moment it's added.
  Future<void> setWishlisted(String uid, String productId, bool wishlisted,
          {double? price}) =>
      FirestoreDb.instance.collection('users').doc(uid).update(<Object, Object?>{
        'wishlistedProductIds': wishlisted
            ? FieldValue.arrayUnion([productId])
            : FieldValue.arrayRemove([productId]),
        FieldPath(['wishlistPrices', productId]): wishlisted && price != null
            ? {'lastSeenPrice': price}
            : FieldValue.delete(),
      });

  /// Writes several wishlist price-baseline changes in one partial update.
  /// Keys are product ids. Each leaf is written explicitly — previousPrice is
  /// set or deleted, never left to "replace the nested map" semantics.
  Future<void> setWishlistPrices(String uid, Map<String, WishlistPrice> entries) {
    if (entries.isEmpty) return Future.value();
    return FirestoreDb.instance.collection('users').doc(uid).update(<Object, Object?>{
      for (final e in entries.entries) ...{
        FieldPath(['wishlistPrices', e.key, 'lastSeenPrice']): e.value.lastSeenPrice,
        FieldPath(['wishlistPrices', e.key, 'previousPrice']):
            e.value.previousPrice ?? FieldValue.delete(),
      },
    });
  }

  /// Edit Profile save: writes only the given basics (name / bio / avatarUrl)
  /// as one partial update — every other field on the user doc is untouched.
  Future<void> updateProfileBasics(
    String uid, {
    String? name,
    String? bio,
    String? avatarUrl,
  }) {
    final changes = <String, dynamic>{
      'name': ?name,
      'bio': ?bio,
      'avatarUrl': ?avatarUrl,
    };
    if (changes.isEmpty) return Future.value();
    return FirestoreDb.instance.collection('users').doc(uid).update(changes);
  }

  Future<void> setBio(String uid, String bio) =>
      FirestoreDb.instance.collection('users').doc(uid).update({'bio': bio});

  Future<void> setAvatarUrl(String uid, String url) =>
      FirestoreDb.instance.collection('users').doc(uid).update({'avatarUrl': url});

  Future<void> setCategories(String uid, List<String> categories) =>
      FirestoreDb.instance.collection('users').doc(uid).update({'categories': categories});

  /// Adds/removes one category key on the user's interests (single-field write).
  Future<void> setCategoryFollowed(String uid, String categoryKey, bool followed) =>
      FirestoreDb.instance.collection('users').doc(uid).update({
        'categories': followed
            ? FieldValue.arrayUnion([categoryKey])
            : FieldValue.arrayRemove([categoryKey]),
      });

  /// Adds/removes one post on the user's bookmarks (single-field write).
  Future<void> setBookmarked(String uid, String postId, bool bookmarked) =>
      FirestoreDb.instance.collection('users').doc(uid).update({
        'bookmarkedPostIds': bookmarked
            ? FieldValue.arrayUnion([postId])
            : FieldValue.arrayRemove([postId]),
      });

  Future<void> setInterestsAndBadge(
          String uid, List<String> categories, String badge) =>
      FirestoreDb.instance.collection('users').doc(uid).update({
        'categories': categories,
        'badge': badge,
      });

  Future<void> deleteUser(String uid) =>
      FirestoreDb.instance.collection('users').doc(uid).delete();
}
