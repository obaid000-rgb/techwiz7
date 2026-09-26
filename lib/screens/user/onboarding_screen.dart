import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_category.dart';
import '../../services/auth_service.dart';
import '../../services/category_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icons.dart';

/// Collects interests (categories) and a profile badge. Two modes:
/// - [OnboardingScreen]: signed-in user with no saved categories (see
///   UserData.hasOnboarded) — writes both to their Firestore user document.
/// - [OnboardingScreen.preLogin]: first-run flow before any account exists —
///   hands the selection to [onPreLoginComplete] instead of writing anywhere.
class OnboardingScreen extends StatefulWidget {
  final UserData? user;
  final Future<void> Function(List<String> categories, String badge)?
      onPreLoginComplete;

  /// Test-only override for the category list (defaults to Firestore).
  @visibleForTesting
  final Stream<List<AppCategory>>? categoriesStream;

  const OnboardingScreen({super.key, required UserData this.user, this.categoriesStream})
      : onPreLoginComplete = null;

  const OnboardingScreen.preLogin(
      {super.key, required this.onPreLoginComplete, this.categoriesStream})
      : user = null;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

const String _kBackgroundAsset = 'assets/images/onboarding/onboarding_bg.jpg';
const Color _kDeepViolet = Color(0xFF6D28D9);

const Map<String, IconData> _kBadgeIcons = {
  'Newcomer': Icons.star_rounded,
  'Enthusiast': Icons.local_fire_department_rounded,
  'Veteran': Icons.workspace_premium_rounded,
  'Collector': Icons.diamond_rounded,
};


class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final Set<String> _selectedCategoryKeys = {};
  String? _selectedBadge;
  bool _saving = false;
  String? _error;

  late final Stream<List<AppCategory>> _categories =
      widget.categoriesStream ?? CategoryService.instance.watchActiveCategories();
  late final AnimationController _bgCtrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 24));
  late final AnimationController _introCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    _bgCtrl.repeat();
    _introCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _bgCtrl.stop();
      _introCtrl.value = 1;
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _introCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_selectedCategoryKeys.isEmpty) {
      setState(() => _error = 'Pick at least one interest to continue.');
      return;
    }
    if (_selectedBadge == null) {
      setState(() => _error = 'Pick a badge to continue.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = widget.user;
      if (user == null) {
        await widget.onPreLoginComplete!(
            _selectedCategoryKeys.toList(), _selectedBadge!);
        return;
      }
      final categories = _selectedCategoryKeys.toList();
      // Partial write of just these two fields — never a full-document
      // overwrite from the (possibly stale) in-memory user.
      await UserService.instance
          .setInterestsAndBadge(user.uid, categories, _selectedBadge!);
      final current = AuthService.instance.currentUser ?? user;
      AuthService.instance.userNotifier.value =
          current.copyWith(categories: categories, badge: _selectedBadge);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your picks. Check your connection and try again.';
        });
      }
    }
  }

  // ── Layout ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Stack(
            fit: StackFit.expand,
            children: [
              _AnimatedBackdrop(controller: _bgCtrl, wide: wide),
              SafeArea(
                child: wide ? _wideContent(constraints) : _phoneContent(constraints),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _phoneContent(BoxConstraints c) {
    final contentWidth = c.maxWidth - 40;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reveal(0.0, _brandHeader(compact: true)),
                SizedBox(height: c.maxHeight * 0.16),
                ..._mainSections(contentWidth, compact: true),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: _reveal(0.55, _startButton()),
        ),
      ],
    );
  }

  Widget _wideContent(BoxConstraints c) {
    const maxW = 640.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 32, 56, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reveal(0.0, _brandHeader(compact: false)),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _mainSections(maxW, compact: false),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _reveal(0.55, _startButton()),
        ],
      ),
    );
  }

  List<Widget> _mainSections(double width, {required bool compact}) => [
        _reveal(0.1, _sparkleRule()),
        const SizedBox(height: 14),
        _reveal(0.15, _headline(compact)),
        const SizedBox(height: 12),
        _reveal(
          0.22,
          Text(
            'Pick a few things you love. We\'ll make your\nFandom Verse experience more personal.',
            style: AppTheme.inter(size: compact ? 13 : 15, color: Colors.white70, height: 1.5),
          ),
        ),
        SizedBox(height: compact ? 24 : 32),
        _reveal(0.3, _sectionTitle('Your Interests')),
        const SizedBox(height: 14),
        _reveal(0.35, _interestGrid(width)),
        SizedBox(height: compact ? 24 : 30),
        _reveal(0.42, _sectionTitle('Your Badge')),
        const SizedBox(height: 14),
        _reveal(0.47, _badgeGrid(width)),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _error == null
              ? const SizedBox(height: 8)
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_error!,
                            style: AppTheme.inter(size: 12, color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ),
        ),
      ];

  /// Staggered fade + slide-up entrance, [start] in 0..1 of the intro.
  Widget _reveal(double start, Widget child) {
    final anim = CurvedAnimation(
      parent: _introCtrl,
      curve: Interval(start, math.min(start + 0.45, 1), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: Offset(0, 18 * (1 - anim.value)), child: child),
      ),
    );
  }

  // ── Branding & headings ───────────────────────────────────────────────────

  Widget _brandHeader({required bool compact}) {
    final mark = compact ? 40.0 : 52.0;
    return Row(
      children: [
        Container(
          width: mark,
          height: mark,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(mark * 0.28),
            gradient: const LinearGradient(
              colors: [AppTheme.accent, AppTheme.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withValues(alpha: 0.55), blurRadius: 18),
            ],
          ),
          alignment: Alignment.center,
          child: Text('FV',
              style: GoogleFonts.orbitron(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: mark * 0.36)),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FANDOM VERSE',
                style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: compact ? 15 : 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: compact ? 3 : 4)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(width: 16, height: 1, color: Colors.white38),
                const SizedBox(width: 6),
                Text('POCKET EDITION',
                    style: GoogleFonts.orbitron(
                        color: Colors.white70, fontSize: compact ? 8 : 10, letterSpacing: 3)),
                const SizedBox(width: 6),
                Container(width: 16, height: 1, color: Colors.white38),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _sparkleRule() => Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 14),
          const SizedBox(width: 10),
          Container(
            width: 90,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.accent.withValues(alpha: 0.8),
                AppTheme.accent.withValues(alpha: 0),
              ]),
            ),
          ),
        ],
      );

  Widget _headline(bool compact) {
    final size = compact ? 28.0 : 40.0;
    final style = GoogleFonts.orbitron(
        fontSize: size, fontWeight: FontWeight.w900, height: 1.1, color: Colors.white);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WELCOME TO', style: style),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFC084FC), AppTheme.accent, AppTheme.cyan],
          ).createShader(b),
          child: Text('FANDOM VERSE', style: style),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 16),
          const SizedBox(width: 10),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.inter(size: 16, color: Colors.white, weight: FontWeight.w600)),
          ),
          const SizedBox(width: 14),
          Container(width: 70, height: 1, color: AppTheme.accent.withValues(alpha: 0.5)),
        ],
      );

  // ── Interest & badge cards ────────────────────────────────────────────────

  Widget _interestGrid(double width) {
    return StreamBuilder<List<AppCategory>>(
      stream: _categories,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _notice(Icons.wifi_off, 'Could not load interests. Check your connection.');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
            ),
          );
        }
        final cats = List<AppCategory>.from(snapshot.data ?? [])
          ..sort((a, b) => a.order.compareTo(b.order));
        if (cats.isEmpty) return _notice(Icons.category_outlined, 'No categories available yet.');

        final cols = width >= 600 ? 5 : (width >= 400 ? 4 : 3);
        const gap = 12.0;
        final cardW = math.min(150.0, (width - gap * (cols - 1)) / cols);
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < cats.length; i++)
              _GlassChoiceCard(
                width: cardW,
                height: cardW * 0.8,
                icon: categoryIcon(cats[i]),
                label: cats[i].name,
                glow: i.isEven ? AppTheme.accent : AppTheme.cyan,
                selected: _selectedCategoryKeys.contains(cats[i].key),
                onTap: () => setState(() {
                  final key = cats[i].key;
                  _selectedCategoryKeys.contains(key)
                      ? _selectedCategoryKeys.remove(key)
                      : _selectedCategoryKeys.add(key);
                  _error = null;
                }),
              ),
          ],
        );
      },
    );
  }

  Widget _badgeGrid(double width) {
    final cols = width >= 400 ? 4 : 2;
    const gap = 12.0;
    final cardW = math.min(175.0, (width - gap * (cols - 1)) / cols);
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final b in kProfileBadges)
          _GlassChoiceCard(
            width: cardW,
            height: 88,
            icon: _kBadgeIcons[b] ?? Icons.military_tech,
            label: b,
            glow: AppTheme.accent,
            selected: _selectedBadge == b,
            onTap: () => setState(() {
              _selectedBadge = b;
              _error = null;
            }),
          ),
      ],
    );
  }

  Widget _notice(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppTheme.inter(size: 12, color: Colors.white60))),
          ],
        ),
      );

  Widget _startButton() => _GlowButton(
        label: 'START EXPLORING',
        loading: _saving,
        onPressed: _saving ? null : _finish,
        shimmer: _bgCtrl,
      );
}

// ── Background: slow parallax artwork + twinkling stars ─────────────────────

class _AnimatedBackdrop extends StatelessWidget {
  final AnimationController controller;
  final bool wide;
  const _AnimatedBackdrop({required this.controller, required this.wide});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * 2 * math.pi;
        final scale = 1.08 + 0.04 * math.sin(t);
        final dx = 14 * math.sin(t);
        final dy = 10 * math.cos(t);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Wide screens: the portrait artwork fills only the right side so
            // the character stays in frame instead of being cropped away.
            Positioned.fill(
              left: wide ? MediaQuery.of(context).size.width * 0.38 : 0,
              child: Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.scale(
                scale: scale,
                child: Image.asset(
                  _kBackgroundAsset,
                  fit: BoxFit.cover,
                  alignment: wide ? const Alignment(-0.3, -0.4) : const Alignment(-0.2, -0.6),
                  errorBuilder: (ctx, e, st) => const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E1B4B), AppTheme.bg],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                  ),
                ),
              ),
              ),
            ),
            // Readability scrim: left-to-right on wide, top-to-bottom on phones.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: wide
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppTheme.bg,
                          AppTheme.bg.withValues(alpha: 0.96),
                          AppTheme.bg.withValues(alpha: 0.35),
                          AppTheme.bg.withValues(alpha: 0.05),
                        ],
                        stops: const [0, 0.4, 0.62, 1],
                      )
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.bg.withValues(alpha: 0.55),
                          AppTheme.bg.withValues(alpha: 0.35),
                          AppTheme.bg.withValues(alpha: 0.9),
                          AppTheme.bg.withValues(alpha: 0.97),
                        ],
                        stops: const [0, 0.18, 0.45, 1],
                      ),
              ),
            ),
            CustomPaint(painter: _StarfieldPainter(controller.value)),
          ],
        );
      },
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double t;
  _StarfieldPainter(this.t);

  static final List<Offset> _stars = List.generate(46, (i) {
    final r = math.Random(i * 7919);
    return Offset(r.nextDouble(), r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _stars.length; i++) {
      final phase = (t * 2 * math.pi * 3) + i;
      final alpha = 0.15 + 0.45 * (0.5 + 0.5 * math.sin(phase));
      paint.color = (i % 3 == 0 ? AppTheme.cyan : Colors.white).withValues(alpha: alpha);
      final p = Offset(_stars[i].dx * size.width, _stars[i].dy * size.height);
      canvas.drawCircle(p, i % 5 == 0 ? 1.6 : 0.9, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.t != t;
}

// ── Glass selection card ─────────────────────────────────────────────────────

class _GlassChoiceCard extends StatefulWidget {
  final double width;
  final double height;
  final IconData icon;
  final String label;
  final Color glow;
  final bool selected;
  final VoidCallback onTap;

  const _GlassChoiceCard({
    required this.width,
    required this.height,
    required this.icon,
    required this.label,
    required this.glow,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_GlassChoiceCard> createState() => _GlassChoiceCardState();
}

class _GlassChoiceCardState extends State<_GlassChoiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final glow = widget.glow;
    return Semantics(
      button: true,
      selected: sel,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : (sel ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                  color: glow.withValues(alpha: 0.55),
                                  blurRadius: 22,
                                  spreadRadius: 1),
                            ]
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: sel
                                  ? [glow.withValues(alpha: 0.38), _kDeepViolet.withValues(alpha: 0.22)]
                                  : [
                                      Colors.white.withValues(alpha: 0.09),
                                      Colors.white.withValues(alpha: 0.03),
                                    ],
                            ),
                            border: Border.all(
                              color: sel
                                  ? glow.withValues(alpha: 0.95)
                                  : Colors.white.withValues(alpha: 0.14),
                              width: sel ? 1.6 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(widget.icon,
                                  size: 28,
                                  color: sel ? Colors.white : glow.withValues(alpha: 0.9)),
                              const SizedBox(height: 8),
                              Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTheme.inter(
                                  size: 12.5,
                                  color: Colors.white,
                                  weight: sel ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: AnimatedScale(
                    scale: sel ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [glow, AppTheme.accent]),
                        border: Border.all(color: AppTheme.bg, width: 2),
                        boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.6), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Primary CTA ──────────────────────────────────────────────────────────────

class _GlowButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final Animation<double> shimmer;

  const _GlowButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    required this.shimmer,
  });

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 140),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(29),
              gradient: const LinearGradient(
                colors: [_kDeepViolet, AppTheme.accent, Color(0xFF7C3AED)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: enabled ? 0.55 : 0.2),
                  blurRadius: 26,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(29),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Slow light sweep across the button.
                  AnimatedBuilder(
                    animation: widget.shimmer,
                    builder: (context, _) {
                      final x = -1.5 + 3 * ((widget.shimmer.value * 3) % 1);
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(x - 0.4, 0),
                            end: Alignment(x + 0.4, 0),
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.18),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Center(
                    child: widget.loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(widget.label,
                                  style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3)),
                              const SizedBox(width: 12),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
