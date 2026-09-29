import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'auth_service.dart';
import 'firestore_db.dart';

class AdminUserException implements Exception {
  final String message;
  const AdminUserException(this.message);
  @override
  String toString() => message;
}


class AdminUserService {
  static final AdminUserService instance = AdminUserService._();
  AdminUserService._();

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
  //  firebasse ka sath wala code 

    final app = await Firebase.initializeApp(
      name: 'admin-create-user-${DateTime.now().microsecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final auth = FirebaseAuth.instanceFor(app: app);
    try {
      final UserCredential cred;
      try {
        cred = await auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      } on FirebaseAuthException catch (e) {
        throw AdminUserException(switch (e.code) {
          'email-already-in-use' => 'An account with this email already exists.',
          'invalid-email' => 'That email address is not valid.',
          'weak-password' => 'That password is too weak. Use at least 8 characters with letters and numbers.',
          'network-request-failed' => 'No internet connection. Try again when you are online.',
          _ => 'Could not create the account (${e.code}).',
        });
      }
      final user = cred.user!;
      final data = UserData(uid: user.uid, name: name.trim(), email: email.trim(), role: role);
      try {
        await FirestoreDb.instance.collection('users').doc(user.uid).set(data.toMap());
      } catch (e) {
        // Don't leave a login with no profile behind: remove the new account.
        debugPrint('Add user: profile write failed, removing account: $e');
        try {
          await user.delete();
        } catch (_) {}
        throw const AdminUserException('Could not save the new user. Check your connection and try again.');
      }
    } finally {
      try {
        await auth.signOut();
      } catch (_) {}
      try {
        await app.delete();
      } catch (e) {
        debugPrint('Add user: temporary app delete failed: $e');
      }
    }
  }
}
