import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_db.dart';
import 'first_run_service.dart';
import 'xp_service.dart';

// Fixed set offered during onboarding
const List<String> kProfileBadges = [
  'Newcomer',
  'Enthusiast',
  'Veteran',
  'Collector',
];

class WishlistPrice {
  final double lastSeenPrice;
  final double? previousPrice;
  const WishlistPrice(this.lastSeenPrice, [this.previousPrice]);

  static Map<String, WishlistPrice> parseAll(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, WishlistPrice>{};
    raw.forEach((id, v) {
      if (v is Map && v['lastSeenPrice'] is num) {
        out['$id'] = WishlistPrice(
          (v['lastSeenPrice'] as num).toDouble(),
          (v['previousPrice'] as num?)?.toDouble(),
        );
      }
    });
    return out;
  }
}

class UserData {
  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final String avatarPresetId;
  final int savedEvents;
  final int bookmarks;
  final String rank;
  final String role; // 'fan' | 'admin'
  final List<String> categories;
  final String bio;
  final String badge;
  final List<String> bookmarkedPostIds;
  final List<String> wishlistedProductIds;
  final Map<String, WishlistPrice> wishlistPrices;
  final List<String> followedFandomIds;
  // Events saved to My Agenda. Written only by EventService's save
  // transaction (with interestedCount) — left out of toMap() like
  // followedFandomIds, so profile saves never overwrite it.
  final List<String> savedEventIds;
  // Fan XP. Written only by XpService (FieldValue.increment) and the admin
  // dialog — left out of toMap() so profile saves never overwrite it.
  final int xp;

  const UserData({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.avatarPresetId = '',
    this.savedEvents = 0,
    this.bookmarks = 0,
    this.rank = 'LEVEL 1',
    this.role = 'fan',
    this.categories = const [],
    this.bio = '',
    this.badge = '',
    this.bookmarkedPostIds = const [],
    this.wishlistedProductIds = const [],
    this.wishlistPrices = const {},
    this.followedFandomIds = const [],
    this.savedEventIds = const [],
    this.xp = 0,
  });

  bool get isAdmin => role == 'admin';
  bool get hasOnboarded => categories.isNotEmpty;

  factory UserData.fromMap(Map<String, dynamic> map, String uid) {
    return UserData(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      avatarPresetId: map['avatarPresetId'] as String? ?? '',
      savedEvents: map['savedEvents'] ?? 0,
      bookmarks: map['bookmarks'] ?? 0,
      rank: map['rank'] ?? 'LEVEL 1',
      role: map['role'] ?? 'fan',
      categories: List<String>.from(map['categories'] ?? []),
      bio: map['bio'] ?? '',
      badge: map['badge'] ?? '',
      bookmarkedPostIds: List<String>.from(map['bookmarkedPostIds'] ?? []),
      wishlistedProductIds:
          List<String>.from(map['wishlistedProductIds'] ?? []),
      wishlistPrices: WishlistPrice.parseAll(map['wishlistPrices']),
      followedFandomIds: map['followedFandomIds'] is List
          ? (map['followedFandomIds'] as List).whereType<String>().toList()
          : const [],
      savedEventIds: map['savedEventIds'] is List
          ? (map['savedEventIds'] as List).whereType<String>().toList()
          : const [],
      xp: map['xp'] is num ? (map['xp'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'avatarPresetId': avatarPresetId,
        'savedEvents': savedEvents,
        'bookmarks': bookmarks,
        'rank': rank,
        'role': role,
        'categories': categories,
        'bio': bio,
        'badge': badge,
        'bookmarkedPostIds': bookmarkedPostIds,
        'wishlistedProductIds': wishlistedProductIds,
      };

  UserData copyWith({
    String? name,
    String? avatarUrl,
    String? avatarPresetId,
    List<String>? categories,
    String? bio,
    String? badge,
    List<String>? bookmarkedPostIds,
    List<String>? wishlistedProductIds,
    Map<String, WishlistPrice>? wishlistPrices,
    List<String>? followedFandomIds,
    List<String>? savedEventIds,
    int? xp,
  }) =>
      UserData(
        uid: uid,
        name: name ?? this.name,
        email: email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        avatarPresetId: avatarPresetId ?? this.avatarPresetId,
        savedEvents: savedEvents,
        bookmarks: bookmarks,
        rank: rank,
        role: role,
        categories: categories ?? this.categories,
        bio: bio ?? this.bio,
        badge: badge ?? this.badge,
        bookmarkedPostIds: bookmarkedPostIds ?? this.bookmarkedPostIds,
        wishlistedProductIds: wishlistedProductIds ?? this.wishlistedProductIds,
        wishlistPrices: wishlistPrices ?? this.wishlistPrices,
        followedFandomIds: followedFandomIds ?? this.followedFandomIds,
        savedEventIds: savedEventIds ?? this.savedEventIds,
        xp: xp ?? this.xp,
      );
}

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  final ValueNotifier<UserData?> userNotifier = ValueNotifier(null);
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool get isLoggedIn => userNotifier.value != null;
  UserData? get currentUser => userNotifier.value;

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      userNotifier.value = null;
      return;
    }
    if (userNotifier.value?.uid == firebaseUser.uid) return;
    try {
      final doc = await FirestoreDb.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists) {
        userNotifier.value = UserData.fromMap(doc.data()!, firebaseUser.uid);
        XpService.instance.award(XpAction.dailyOpen);
      } else if (_googleSignInInProgress || userNotifier.value?.uid == firebaseUser.uid) {
        // signInWithGoogle / register() is creating this profile itself.
        return;
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

  Future<void> signIn({required String email, required String password}) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // True while signInWithGoogle is signing in, so _onAuthStateChanged
  // doesn't race it to create a first-time Google user's profile.
  bool _googleSignInInProgress = false;

  /// Returns true if signed in, false if the user closed the Google account
  /// picker. Throws on real failures (see LoginScreen for the messages).
  Future<bool> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return false; // picker cancelled

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final pending = await FirstRunService.instance.readPending();
    _googleSignInInProgress = true;
    try {
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user!;
      if (result.additionalUserInfo?.isNewUser ?? false) {
        // First Google sign-in = registration: create the profile like
        // register() does, with the Google name/photo and any interests
        // picked before login on this device.
        final userData = UserData(
          uid: user.uid,
          name: user.displayName ?? user.email!.split('@').first,
          email: user.email!,
          avatarUrl: user.photoURL ?? '',
          role: 'fan',
          categories: pending?.categories ?? const [],
          badge: pending?.badge ?? '',
        );
        userNotifier.value = userData;
        await FirestoreDb.instance.collection('users').doc(user.uid).set(userData.toMap());
        if (pending != null) await FirstRunService.instance.clearPending();
      }
    } finally {
      _googleSignInInProgress = false;
    }
    return true;
  }

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
      role: 'fan',
    );
    userNotifier.value = userData;
    FirestoreDb.instance
        .collection('users')
        .doc(cred.user!.uid)
        .set(userData.toMap())
        .catchError((_) {});
  }

  Future<void> signOut() async {
    // Google sign-out can throw (e.g. no Google session, or web without a
    // Google client id); it must never block logging out of the app.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }
}
