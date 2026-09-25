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

  Future<void> deleteUser(String uid) =>
      FirestoreDb.instance.collection('users').doc(uid).delete();
}
