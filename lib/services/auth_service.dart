import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firestore_db.dart';

// Fixed set offered during onboarding — no existing badge art/names were
// found anywhere in the project, so these are new.
const List<String> kProfileBadges = [
  'Newcomer',
  'Enthusiast',
  'Veteran',
  'Collector',
];

/// Price baseline for one wishlisted product, stored on the user doc at
/// `wishlistPrices.<productId>`. [lastSeenPrice] is what the next check
/// compares against; [previousPrice] is the price before the last detected
/// change, kept so the Wishlist can badge it until the fan opens the product.
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
  final int savedEvents;
  final int bookmarks;
  final String rank;
  final String role; // 'fan' | 'admin'
  final List<String> categories;
  final String bio;
  final String badge; // '' = none selected (pre-onboarding-feature accounts)
  final List<String> bookmarkedPostIds;
  final List<String> wishlistedProductIds;
  // productId -> price baselines for wishlist price-change alerts.
  final Map<String, WishlistPrice> wishlistPrices;

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
    this.bio = '',
    this.badge = '',
    this.bookmarkedPostIds = const [],
    this.wishlistedProductIds = const [],
    this.wishlistPrices = const {},
  });

  bool get isAdmin => role == 'admin';

  /// Whether this account has completed onboarding (category selection).
  bool get hasOnboarded => categories.isNotEmpty;

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
      bio: map['bio'] ?? '',
      badge: map['badge'] ?? '',
      bookmarkedPostIds: List<String>.from(map['bookmarkedPostIds'] ?? []),
      wishlistedProductIds:
          List<String>.from(map['wishlistedProductIds'] ?? []),
      wishlistPrices: WishlistPrice.parseAll(map['wishlistPrices']),
    );
  }

  // wishlistPrices is deliberately NOT here: it's only written by targeted
  // field-path updates, so a full-profile update can't reset baselines.
  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
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
    List<String>? categories,
    String? bio,
    String? badge,
    List<String>? bookmarkedPostIds,
    List<String>? wishlistedProductIds,
    Map<String, WishlistPrice>? wishlistPrices,
  }) =>
      UserData(
        uid: uid,
        name: name ?? this.name,
        email: email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
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
      );
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
