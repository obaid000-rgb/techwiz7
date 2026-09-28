import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/bookmark_store.dart';
import '../../services/first_run_service.dart';
import '../../services/notification_service.dart';
import '../../services/trending_service.dart';
import '../../services/wishlist_price_service.dart';
import '../../services/onboarding_slide_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../onboarding/onboarding_carousel_screen.dart';
import '../home/fan_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const Duration _maxWait = Duration(seconds: 8);
  static const Duration _minShow = Duration(seconds: 2);

  // Logo: fade + scale 0.85 -> 1.0 over 600 ms; text fades in 200 ms later.
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  // Progress bar: fills over the 2-second minimum.
  late final AnimationController _progress = AnimationController(vsync: this, duration: _minShow);
  // Indeterminate sweep, only if the checks outlast the 2 seconds.
  late final AnimationController _sweep =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  bool _indeterminate = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.init().catchError((_) {});
    // Wishlist price checks on sign-in and every return to the foreground.
    WishlistPriceService.instance.start();
    TrendingService.instance.start();
    // Bookmarks = offline copies: one-time migration + sync on each sign-in.
    BookmarkStore.instance.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      // Reduced motion: everything shown immediately, no entrance.
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
    _progress.forward();
    _start();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _progress.dispose();
    _sweep.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final navigator = Navigator.of(context);
    // Minimum duration: the startup checks start now, in parallel with a
    // 2-second timer, and the splash leaves only when BOTH are done. Fast
    // checks still get the full 2 seconds; slow ones keep the splash up
    // (the bar switches to an indeterminate sweep) until they finish, but
    // never past the existing 8-second timeout, which still applies to
    // the checks themselves.
    final minShow = Future<void>.delayed(_minShow);
    final Future<Widget> decision = _decideNextScreen(navigator)
        .timeout(_maxWait)
        .catchError((Object _) => const FanHomeScreen() as Widget);
    unawaited(minShow.then((_) {
      if (mounted && !_checksDone) {
        setState(() => _indeterminate = true);
        if (!MediaQuery.of(context).disableAnimations) _sweep.repeat();
      }
    }));
    final next = await decision;
    // Timed out or failed above: fall through to the guest landing.
    // FanHomeScreen listens to AuthService itself, so it still updates if
    // the profile finishes loading afterwards.
    _checksDone = true;
    await minShow;
    if (!mounted) return;
    navigator.pushReplacement(PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => next,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ));

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

  bool _checksDone = false;

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
    final logoFade = CurvedAnimation(parent: _entrance, curve: const Interval(0, 0.75, curve: Curves.easeOut));
    final textFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.25, 1, curve: Curves.easeOut));
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // Soft brand-purple glow behind the logo.
          Center(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.accent.withValues(alpha: 0.30),
                  AppTheme.accent.withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: logoFade,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.85, end: 1).animate(logoFade),
                    child: const AppLogo.large(),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: textFade,
                  child: Column(children: [
                    Text(
                      'Fandom Verse',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'POCKET EDITION',
                      style: GoogleFonts.orbitron(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Your Fandom. Your Universe.',
                      style: AppTheme.inter(size: 13, color: AppTheme.textMuted),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 72,
            child: Center(
              child: SizedBox(
                width: width * 0.4,
                height: 4,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_progress, _sweep]),
                  builder: (context, _) => CustomPaint(
                    painter: _BarPainter(
                      progress: _progress.value,
                      indeterminate: _indeterminate,
                      sweep: _sweep.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin rounded bar with a purple-to-cyan fill: fills left to right, or
/// (indeterminate) a segment sweeping across.
class _BarPainter extends CustomPainter {
  final double progress;
  final bool indeterminate;
  final double sweep;
  _BarPainter({required this.progress, required this.indeterminate, required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, r);
    canvas.drawRRect(track, Paint()..color = Colors.white.withValues(alpha: 0.08));
    final Rect fill;
    if (indeterminate) {
      final segment = size.width * 0.35;
      final start = -segment + (size.width + segment) * sweep;
      fill = Rect.fromLTWH(start, 0, segment, size.height).intersect(Offset.zero & size);
    } else {
      fill = Rect.fromLTWH(0, 0, size.width * progress.clamp(0, 1), size.height);
    }
    if (fill.width <= 0) return;
    final paint = Paint()
      ..shader = const LinearGradient(colors: [AppTheme.accent, AppTheme.cyan])
          .createShader(Offset.zero & size);
    canvas.save();
    canvas.clipRRect(track);
    canvas.drawRRect(RRect.fromRectAndRadius(fill, r), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.progress != progress || old.indeterminate != indeterminate || old.sweep != sweep;
}
