import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firestore_db.dart';

class UserData {
  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final int savedEvents;
  final int bookmarks;
  final String rank;
  final String role; // 'fan' | 'admin'
  final List<String> categories;

  const UserData({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.savedEvents = 0,
    this.bookmarks = 0,
    this.rank = 'LEVEL 1',
    this.role = 'fan',
    this.categories = const [],
  });

  bool get isAdmin => role == 'admin';

  factory UserData.fromMap(Map<String, dynamic> map, String uid) {
    return UserData(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      savedEvents: map['savedEvents'] ?? 0,
      bookmarks: map['bookmarks'] ?? 0,
      rank: map['rank'] ?? 'LEVEL 1',
      role: map['role'] ?? 'fan',
      categories: List<String>.from(map['categories'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'savedEvents': savedEvents,
        'bookmarks': bookmarks,
        'rank': rank,
        'role': role,
        'categories': categories,
      };
}

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  final ValueNotifier<UserData?> userNotifier = ValueNotifier(null);

  bool get isLoggedIn => userNotifier.value != null;
  UserData? get currentUser => userNotifier.value;

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      userNotifier.value = null;
      return;
    }
    // Already set by register() — skip to avoid race condition
    if (userNotifier.value?.uid == firebaseUser.uid) return;
    try {
      final doc = await FirestoreDb.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists) {
        userNotifier.value = UserData.fromMap(doc.data()!, firebaseUser.uid);
      } else {
        final name = firebaseUser.displayName ??
            firebaseUser.email!.split('@').first;
        final userData = UserData(
          uid: firebaseUser.uid,
          name: name,
          email: firebaseUser.email!,
          role: 'fan',
        );
        userNotifier.value = userData;
        FirestoreDb.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userData.toMap())
            .catchError((_) {});
      }
    } catch (_) {
      // Firestore unavailable — fall back to Auth data so app doesn't hang
      final name = firebaseUser.displayName ??
          firebaseUser.email!.split('@').first;
      userNotifier.value = UserData(
        uid: firebaseUser.uid,
        name: name,
        email: firebaseUser.email!,
        role: 'fan',
      );
    }
  }

  /// Sign in with email + password. Throws [FirebaseAuthException] on failure.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // _onAuthStateChanged fires and reads role from Firestore
  }

  /// Create account, save profile to Firestore as 'fan'. Throws [FirebaseAuthException] on failure.
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final displayName =
        name.trim().isNotEmpty ? name.trim() : email.split('@').first;
    final userData = UserData(
      uid: cred.user!.uid,
      name: displayName,
      email: email.trim(),
      role: 'fan', // new registrations are always fans
    );
    // Set immediately so UI updates and Navigator.pop() fires
    userNotifier.value = userData;
    // Write to Firestore in background
    FirestoreDb.instance
        .collection('users')
        .doc(cred.user!.uid)
        .set(userData.toMap())
        .catchError((_) {});
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    // _onAuthStateChanged fires and sets userNotifier to null
  }
}
