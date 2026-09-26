import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/first_run_service.dart';
import '../services/notification_service.dart';
import '../services/trending_service.dart';
import '../services/wishlist_price_service.dart';
import '../services/onboarding_slide_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_carousel_screen.dart';
import 'user/fan_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _maxWait = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    NotificationService.instance.init().catchError((_) {});
    // Wishlist price checks on sign-in and every return to the foreground.
    WishlistPriceService.instance.start();
    TrendingService.instance.start();
    _start();
  }

  Future<void> _start() async {
    final navigator = Navigator.of(context);
    Widget next;
    try {
      next = await _decideNextScreen(navigator).timeout(_maxWait);
    } catch (_) {
      // Timed out or failed: fall through to the guest landing. FanHomeScreen
      // listens to AuthService itself, so it still updates if the profile
      // finishes loading afterwards.
      next = const FanHomeScreen();
    }
    if (!mounted) return;
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => next));

    final fromNotification = await NotificationService.instance
        .launchedFromNotification()
        .catchError((_) => false);
    if (next is! FanHomeScreen) return;
    if (fromNotification) {
      NotificationService.instance.openNotificationsScreen();
    } else {
      NotificationService.instance.maybeAskOnce();
    }
  }

  /// Routing decision:
  /// 1. First-run sequence (slides + interest selection) not completed on
  ///    this install → admin slides if any exist, else straight to interest
  ///    selection (also if slides can't be loaded). Applies regardless of
  ///    auth state; the sequence ends on FanHomeScreen.
  /// 2. Otherwise → FanHomeScreen, which is both the guest landing and the
  ///    signed-in Home shell (it shows Select Fandoms itself if needed).
  ///    For a signed-in user we wait for AuthService to load their Firestore
  ///    profile first, so Home opens already signed in instead of flashing
  ///    the guest top bar for a moment.
  Future<Widget> _decideNextScreen(NavigatorState navigator) async {
    if (!await FirstRunService.instance.hasSeenOnboarding()) {
      try {
        final slides = await OnboardingSlideService.instance
            .fetchSlides()
            .timeout(const Duration(seconds: 5));
        if (slides.isNotEmpty) return const OnboardingCarouselScreen();
      } catch (_) {}
      return preLoginInterestSelection(navigator);
    }

    // Touching AuthService.instance starts its authStateChanges listener.
    final auth = AuthService.instance;
    // First event = the persisted session (or null) restored by Firebase Auth.
    final firebaseUser = await FirebaseAuth.instance.authStateChanges().first;
    if (firebaseUser == null) return const FanHomeScreen();

    if (auth.currentUser?.uid != firebaseUser.uid) {
      final loaded = Completer<void>();
      void onChange() {
        if (auth.currentUser?.uid == firebaseUser.uid && !loaded.isCompleted) {
          loaded.complete();
        }
      }
      auth.userNotifier.addListener(onChange);
      try {
        await loaded.future;
      } finally {
        auth.userNotifier.removeListener(onChange);
      }
    }
    return const FanHomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, AppTheme.cyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'F',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 38,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.cyan, AppTheme.accent, AppTheme.pink],
              ).createShader(bounds),
              child: Text(
                'FANDOM VERSE',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'POCKET EDITION',
              style: GoogleFonts.orbitron(
                color: Colors.blueGrey,
                fontSize: 10,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
            ),
          ],
        ),
      ),
    );
  }
}
