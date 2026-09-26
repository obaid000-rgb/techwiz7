import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_category.dart';
import '../theme/app_theme.dart';
import '../utils/category_icons.dart';

const String _kArtwork = 'assets/images/onboarding/onboarding_bg.jpg';

/// Profile "My Fandoms" card. Purely presentational: shows the user's saved
/// interest categories and calls [onEdit] to change them.
class MyFandomsCard extends StatelessWidget {
  /// The user's saved category keys (UserData.categories).
  final List<String> categoryKeys;

  /// All categories (to resolve names/icons); null while loading.
  final List<AppCategory>? categories;
  final bool hasError;

  /// Opens the fandom picker; null disables editing (e.g. while loading).
  final VoidCallback? onEdit;

  const MyFandomsCard({
    super.key,
    required this.categoryKeys,
    required this.categories,
    this.hasError = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.28),
                blurRadius: 28,
                spreadRadius: -4,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Deep cosmic base.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF140B33), Color(0xFF0B0F2A), Color(0xFF12093A)],
                      ),
                    ),
                  ),
                ),
                // Character artwork on the right, faded into the base.
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: constraints.maxWidth * (wide ? 0.5 : 0.62),
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [Colors.transparent, Colors.black],
                      stops: [0, 0.55],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Opacity(
                      opacity: wide ? 0.9 : 0.55,
                      child: Image.asset(
                        _kArtwork,
                        fit: BoxFit.cover,
                        alignment: const Alignment(-0.1, -0.55),
                        errorBuilder: (ctx, e, st) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                // Soft purple bloom behind the title.
                Positioned(
                  left: -60,
                  top: -80,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppTheme.accent.withValues(alpha: 0.28),
                        AppTheme.accent.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                ),
                const Positioned.fill(child: CustomPaint(painter: _SparklePainter())),
                // Glass sheen + glowing edge.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.45)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.07),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0, 0.45],
                      ),
                    ),
                  ),
                ),
                // Accent rail on the left edge.
                Positioned(
                  left: 0,
                  top: 26,
                  bottom: 26,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppTheme.accent, AppTheme.cyan],
                      ),
                      boxShadow: [
                        BoxShadow(color: AppTheme.accent.withValues(alpha: 0.8), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(wide ? 26 : 18, 20, wide ? 22 : 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(wide),
                      SizedBox(height: wide ? 20 : 16),
                      _body(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int get _count => categoryKeys.length;

  Widget _header(bool wide) {
    final counter = _CounterPill(count: _count);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeartMark(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Fandoms',
                  style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: wide ? 20 : 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Container(
                width: 28,
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.cyan]),
                ),
              ),
              const SizedBox(height: 6),
              Text('Your favorite fandoms, always in your universe.',
                  style: AppTheme.inter(size: wide ? 13 : 11.5, color: Colors.white60)),
              if (!wide) ...[
                const SizedBox(height: 10),
                counter,
              ],
            ],
          ),
        ),
        if (wide) ...[
          const SizedBox(width: 12),
          counter,
        ],
      ],
    );
  }

  Widget _body() {
    if (hasError) {
      return _message(Icons.wifi_off, 'Could not load your fandoms.');
    }
    if (categories == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
        ),
      );
    }
    final byKey = {for (final c in categories!) c.key: c};
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (categoryKeys.isEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text('No fandoms picked yet.',
                style: AppTheme.inter(size: 12, color: Colors.white60)),
          ),
        for (var i = 0; i < categoryKeys.length; i++)
          _FandomChip(
            label: byKey[categoryKeys[i]]?.name ?? categoryKeys[i],
            icon: byKey[categoryKeys[i]] != null
                ? categoryIcon(byKey[categoryKeys[i]]!)
                : Icons.auto_awesome_rounded,
            glow: const [AppTheme.accent, Color(0xFF6366F1), AppTheme.cyan][i % 3],
          ),
        _EditChip(onTap: onEdit, emptyState: categoryKeys.isEmpty),
      ],
    );
  }

  Widget _message(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTheme.inter(size: 12, color: Colors.white60))),
        ],
      );
}

class _HeartMark extends StatelessWidget {
  const _HeartMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: AppTheme.accent.withValues(alpha: 0.55), blurRadius: 18),
        ],
      ),
      alignment: Alignment.center,
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF60A5FA), AppTheme.accent, Color(0xFFC084FC)],
        ).createShader(rect),
        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  final int count;
  const _CounterPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0B0F2A).withValues(alpha: 0.75),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text('$count ${count == 1 ? 'Interest' : 'Interests'}',
              style: AppTheme.inter(size: 12, color: Colors.white, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// A saved fandom, shown as a glowing glass pill with its icon.
class _FandomChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color glow;
  const _FandomChip({required this.label, required this.icon, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [glow.withValues(alpha: 0.30), const Color(0xFF1E1B4B).withValues(alpha: 0.55)],
        ),
        border: Border.all(color: glow.withValues(alpha: 0.85), width: 1.3),
        boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.4), blurRadius: 14)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              colors: [Colors.white, glow],
            ).createShader(rect),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.inter(size: 13, color: Colors.white, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Opens the picker. Dashed-feeling ghost pill so it reads as an action, not
/// a saved fandom.
class _EditChip extends StatelessWidget {
  final VoidCallback? onTap;
  final bool emptyState;
  const _EditChip({required this.onTap, required this.emptyState});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: emptyState ? 'Pick fandoms' : 'Edit fandoms',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                  color: Colors.white.withValues(alpha: enabled ? 0.28 : 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyState ? Icons.add_rounded : Icons.edit_rounded,
                    color: enabled ? AppTheme.cyan : Colors.white24, size: 16),
                const SizedBox(width: 6),
                Text(emptyState ? 'Pick fandoms' : 'Edit',
                    style: AppTheme.inter(
                        size: 13,
                        color: enabled ? Colors.white : Colors.white38,
                        weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Static sparkles and a few drifting petals for depth.
class _SparklePainter extends CustomPainter {
  const _SparklePainter();

  static final List<Offset> _points = List.generate(28, (i) {
    final r = math.Random(i * 131 + 7);
    return Offset(r.nextDouble(), r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint();
    for (var i = 0; i < _points.length; i++) {
      final p = Offset(_points[i].dx * size.width, _points[i].dy * size.height);
      dot.color = (i % 4 == 0 ? AppTheme.cyan : Colors.white)
          .withValues(alpha: 0.18 + (i % 5) * 0.08);
      canvas.drawCircle(p, i % 6 == 0 ? 1.5 : 0.8, dot);
    }
    final petal = Paint()..color = const Color(0xFFA855F7).withValues(alpha: 0.35);
    for (final f in const [Offset(0.62, 0.18), Offset(0.9, 0.78), Offset(0.47, 0.88)]) {
      canvas.save();
      canvas.translate(f.dx * size.width, f.dy * size.height);
      canvas.rotate(0.6);
      canvas.drawOval(const Rect.fromLTWH(-5, -2.5, 10, 5), petal);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => false;
}
