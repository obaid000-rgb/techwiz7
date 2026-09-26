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
  /// array field (arrayUnion/arrayRemove), so it can't overwrite anything
  /// else on the user document with stale in-memory values.
  Future<void> setWishlisted(String uid, String productId, bool wishlisted) =>
      FirestoreDb.instance.collection('users').doc(uid).update({
        'wishlistedProductIds': wishlisted
            ? FieldValue.arrayUnion([productId])
            : FieldValue.arrayRemove([productId]),
      });

  Future<void> deleteUser(String uid) =>
      FirestoreDb.instance.collection('users').doc(uid).delete();
}
