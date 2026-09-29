import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_info.dart';
import 'firestore_db.dart';
import 'first_run_service.dart';
import 'notification_service.dart';
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
          v['previousPrice'] is num ? (v['previousPrice'] as num).toDouble() : null,
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
  // True for the stand-in AuthService publishes when the real users/{uid}
  // doc couldn't be loaded yet (offline, no cache). It is replaced as soon
  // as the real doc arrives. Its empty fields are NOT the fan's data, so it
  // counts as onboarded (no onboarding over real interests) and must never
  // be written back to Firestore.
  final bool isPlaceholder;
  // Set by an admin (Users > Deactivate). A disabled account is signed out
  // as soon as its profile loads or the flag changes. Admin-only field:
  // left out of toMap() and blocked for owners in firestore.rules.
  final bool disabled;

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
    this.isPlaceholder = false,
    this.disabled = false,
  });

  bool get isAdmin => role == 'admin';
  bool get hasOnboarded => isPlaceholder || categories.isNotEmpty;

  // Defensive readers: a legacy or console-edited doc with a wrong-typed
  // field falls back to the default instead of throwing.
  static String _str(Object? v, [String fallback = '']) =>
      v is String ? v : fallback;
  static int _int(Object? v) => v is num ? v.toInt() : 0;
  static List<String> _strList(Object? v) =>
      v is List ? v.whereType<String>().toList() : const [];

  factory UserData.fromMap(Map<String, dynamic> map, String uid) {
    return UserData(
      uid: uid,
      name: _str(map['name']),
      email: _str(map['email']),
      avatarUrl: _str(map['avatarUrl']),
      avatarPresetId: _str(map['avatarPresetId']),
      savedEvents: _int(map['savedEvents']),
      bookmarks: _int(map['bookmarks']),
      rank: _str(map['rank'], 'LEVEL 1'),
      role: _str(map['role'], 'fan'),
      categories: _strList(map['categories']),
      bio: _str(map['bio']),
      badge: _str(map['badge']),
      bookmarkedPostIds: _strList(map['bookmarkedPostIds']),
      wishlistedProductIds: _strList(map['wishlistedProductIds']),
      wishlistPrices: WishlistPrice.parseAll(map['wishlistPrices']),
      followedFandomIds: _strList(map['followedFandomIds']),
      savedEventIds: _strList(map['savedEventIds']),
      xp: _int(map['xp']),
      disabled: map['disabled'] == true,
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
        isPlaceholder: isPlaceholder,
        disabled: disabled,
      );
}

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  final ValueNotifier<UserData?> userNotifier = ValueNotifier(null);
  // Created on first use and never on web: the google_sign_in web plugin
  // needs its own web client id (not configured), and without it the
  // plugin threw at startup, which paused debug sessions on a white page.
  // Web signs in with Firebase's Google popup instead (signInWithGoogle).
  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn => _googleSignInInstance ??= GoogleSignIn();

  bool get isLoggedIn => userNotifier.value != null;
  UserData? get currentUser => userNotifier.value;

  // How long a new-profile write may take before we accept it as queued
  // (Firestore persists offline writes and syncs them later).
  static const Duration _profileWriteTimeout = Duration(seconds: 15);
  // How long to wait for the real profile before publishing a placeholder,
  // so the splash screen (which waits for userNotifier) can't hang forever.
  static const Duration _placeholderDelay = Duration(seconds: 8);
  static const Duration _profileRetryDelay = Duration(seconds: 20);

  // Retry state for a profile that failed to load (see _watchProfile).
  String? _watchedUid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  Timer? _placeholderTimer;
  Timer? _retryTimer;
  // True while the shown profile came from the local cache only, so the
  // first server snapshot may still replace it.
  bool _showingCachedProfile = false;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      FirestoreDb.instance.collection('users').doc(uid);

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser?.uid != _watchedUid) _stopProfileWatch();
    if (firebaseUser?.uid != _disabledWatchUid) _stopDisabledWatch();
    if (firebaseUser == null) {
      userNotifier.value = null;
      return;
    }
    final shown = userNotifier.value;
    // Already have this fan's real profile. A placeholder doesn't count.
    if (shown != null && shown.uid == firebaseUser.uid && !shown.isPlaceholder) {
      return;
    }
    final DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await _userDoc(firebaseUser.uid).get();
    } catch (e) {
      debugPrint('Profile load failed for ${firebaseUser.uid}: $e');
      // Offline / transient: use the cached copy if there is one, and keep
      // listening so the real doc replaces it (or the placeholder) later.
      try {
        final cached = await _userDoc(firebaseUser.uid)
            .get(const GetOptions(source: Source.cache));
        final data = cached.data();
        if (cached.exists && data != null) {
          _publishProfile(firebaseUser.uid, data, fromCache: true);
        }
      } catch (_) {}
      _watchProfile(firebaseUser);
      return;
    }
    _stopProfileWatch(); // a retry succeeded
    final data = doc.data();
    if (doc.exists && data != null) {
      _publishProfile(firebaseUser.uid, data, fromCache: false);
    } else {
      await _createMissingProfile(firebaseUser);
    }
  }

  /// Publishes a loaded users/{uid} doc, unless it would replace newer
  /// in-memory state (a real, server-confirmed profile for the same fan).
  void _publishProfile(String uid, Map<String, dynamic> data,
      {required bool fromCache}) {
    if (FirebaseAuth.instance.currentUser?.uid != uid) return;
    final shown = userNotifier.value;
    final firstLoad =
        shown == null || shown.uid != uid || shown.isPlaceholder;
    if (!firstLoad && !(_showingCachedProfile && !fromCache)) return;
    if (data['disabled'] == true) {
      _signOutDisabled();
      return;
    }
    _showingCachedProfile = fromCache;
    userNotifier.value = UserData.fromMap(data, uid);
    _watchDisabled(uid);
    if (firstLoad) XpService.instance.award(XpAction.dailyOpen);
  }

  // ── Deactivated accounts ──────────────────────────────────────────────────

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _disabledSub;
  String? _disabledWatchUid;

  /// Signs the fan out the moment an admin deactivates them mid-session.
  void _watchDisabled(String uid) {
    if (_disabledWatchUid == uid && _disabledSub != null) return;
    _disabledSub?.cancel();
    _disabledWatchUid = uid;
    _disabledSub = _userDoc(uid).snapshots().listen((snap) {
      if (snap.data()?['disabled'] == true &&
          FirebaseAuth.instance.currentUser?.uid == uid) {
        _signOutDisabled();
      }
    }, onError: (Object e) => debugPrint('Account status listen failed: $e'));
  }

  void _stopDisabledWatch() {
    _disabledSub?.cancel();
    _disabledSub = null;
    _disabledWatchUid = null;
  }

  bool _showingDisabledNotice = false;

  Future<void> _signOutDisabled() async {
    _stopDisabledWatch();
    await signOut();
    final context = NotificationService.navigatorKey.currentContext;
    if (context == null || !context.mounted || _showingDisabledNotice) return;
    _showingDisabledNotice = true;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account deactivated'),
        content: Text(
          'Your account has been deactivated by the ${AppInfo.appName} team, '
          'so you have been signed out. You can still browse as a guest.\n\n'
          'If you think this is a mistake, contact us'
          '${AppInfo.supportEmail == null ? ' from Contact Us' : ' at ${AppInfo.supportEmail}'}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
    _showingDisabledNotice = false;
  }

  /// The profile couldn't be read from the server: listen to users/{uid}
  /// until a server snapshot arrives, retrying on errors. If nothing at all
  /// is shown after [_placeholderDelay], publish a placeholder (see
  /// UserData.isPlaceholder) so the app opens instead of hanging.
  void _watchProfile(User firebaseUser) {
    final uid = firebaseUser.uid;
    _stopProfileWatch();
    _watchedUid = uid;
    if (userNotifier.value?.uid != uid) {
      _placeholderTimer = Timer(_placeholderDelay, () {
        if (_watchedUid != uid || userNotifier.value?.uid == uid) return;
        if (FirebaseAuth.instance.currentUser?.uid != uid) return;
        userNotifier.value = UserData(
          uid: uid,
          name: firebaseUser.displayName ??
              (firebaseUser.email ?? '').split('@').first,
          email: firebaseUser.email ?? '',
          isPlaceholder: true,
        );
      });
    }
    _profileSub = _userDoc(uid).snapshots().listen((snap) {
      if (_watchedUid != uid) return;
      final data = snap.data();
      if (snap.exists && data != null) {
        _publishProfile(uid, data, fromCache: snap.metadata.isFromCache);
        if (!snap.metadata.isFromCache) _stopProfileWatch();
      } else if (!snap.metadata.isFromCache) {
        // The server confirms there's no profile doc: create one.
        _stopProfileWatch();
        _createMissingProfile(firebaseUser);
      }
    }, onError: (Object e) {
      debugPrint('Profile listen failed for $uid: $e');
      _profileSub?.cancel();
      _profileSub = null;
      _retryTimer?.cancel();
      _retryTimer = Timer(_profileRetryDelay, () {
        if (_watchedUid == uid &&
            FirebaseAuth.instance.currentUser?.uid == uid) {
          _onAuthStateChanged(FirebaseAuth.instance.currentUser);
        }
      });
    });
  }

  void _stopProfileWatch() {
    _profileSub?.cancel();
    _profileSub = null;
    _placeholderTimer?.cancel();
    _placeholderTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _watchedUid = null;
  }

  /// Signed in, but the server has no users/{uid} doc (e.g. created in the
  /// console): create the default fan profile.
  Future<void> _createMissingProfile(User firebaseUser) async {
    final shown = userNotifier.value;
    if (_profileCreationInProgress ||
        (shown != null && shown.uid == firebaseUser.uid && !shown.isPlaceholder)) {
      // signInWithGoogle / register() is creating this profile itself.
      return;
    }
    final userData = UserData(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ??
          (firebaseUser.email ?? '').split('@').first,
      email: firebaseUser.email ?? '',
      role: 'fan',
    );
    try {
      await _writeNewProfile(userData);
    } catch (e) {
      // Nothing to overwrite (the doc doesn't exist), so still show the
      // default profile; onboarding writes the interests afterwards.
      debugPrint('Creating profile for ${firebaseUser.uid} failed: $e');
    }
    if (FirebaseAuth.instance.currentUser?.uid != firebaseUser.uid) return;
    _showingCachedProfile = false;
    userNotifier.value = userData;
  }

  /// Writes a brand-new profile doc. A timeout is accepted (the write stays
  /// queued offline); a real failure (e.g. permission-denied) throws.
  Future<void> _writeNewProfile(UserData userData) async {
    try {
      await _userDoc(userData.uid)
          .set(userData.toMap())
          .timeout(_profileWriteTimeout);
    } on TimeoutException {
      debugPrint('Profile write for ${userData.uid} queued (offline?)');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // True while signInWithGoogle / register() are signing in, so
  // _onAuthStateChanged doesn't race them to create a new user's profile.
  bool _profileCreationInProgress = false;

  /// Returns true if signed in, false if the user closed the Google account
  /// picker. Throws on real failures (see LoginScreen for the messages).
  Future<bool> signInWithGoogle() async {
    OAuthCredential? credential;
    if (!kIsWeb) {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false; // picker cancelled
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    }

    final pending = await FirstRunService.instance.readPending();
    _profileCreationInProgress = true;
    try {
      final UserCredential result;
      if (credential != null) {
        result = await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        // Web: Firebase's own Google popup.
        try {
          result = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
        } on FirebaseAuthException catch (e) {
          if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') return false;
          rethrow;
        }
      }
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
        _showingCachedProfile = false;
        userNotifier.value = userData;
        await _writeNewProfile(userData);
        if (pending != null) await FirstRunService.instance.clearPending();
      }
    } finally {
      _profileCreationInProgress = false;
    }
    return true;
  }

  /// Creates the auth account and its users/{uid} profile. Throws if either
  /// fails; a failed profile write undoes the sign-up (deletes the new auth
  /// user, or at least signs out) so the fan can simply try again.
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _profileCreationInProgress = true;
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      final displayName =
          name.trim().isNotEmpty ? name.trim() : email.split('@').first;
      final userData = UserData(
        uid: user.uid,
        name: displayName,
        email: email.trim(),
        role: 'fan',
      );
      _showingCachedProfile = false;
      userNotifier.value = userData;
      try {
        await _writeNewProfile(userData);
      } catch (e) {
        debugPrint('Profile write for ${user.uid} failed, undoing sign-up: $e');
        userNotifier.value = null;
        try {
          await user.delete();
        } catch (_) {
          try {
            await FirebaseAuth.instance.signOut();
          } catch (_) {}
        }
        rethrow;
      }
    } finally {
      _profileCreationInProgress = false;
    }
  }

  Future<void> signOut() async {
    // Google sign-out can throw (e.g. no Google session, or web without a
    // Google client id); it must never block logging out of the app.
    try {
      if (!kIsWeb) await _googleSignIn.signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }
}
