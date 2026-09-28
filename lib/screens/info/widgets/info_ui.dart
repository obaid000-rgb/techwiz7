import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';

/// Shared look for the About Us and Contact Us pages: a cinematic dark
/// purple backdrop, glass cards, glowing icons and gradient buttons, all
/// built on AppTheme's palette.
class InfoColors {
  InfoColors._();
  static const Color deepPurple = Color(0xFF1A0B2E);
  static const Color lavender = Color(0xFFE9D5FF);
  static const Color glassFill = Color(0x0FFFFFFF);
  static const Color glassBorder = Color(0x1FFFFFFF);
  static const LinearGradient brand = LinearGradient(
    colors: [AppTheme.accent, AppTheme.pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Page shell: transparent app bar over the backdrop, centred content
/// column (max 760px) so it reads well on phones and wide Chrome windows.
class InfoPageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const InfoPageScaffold({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTheme.orbitron(size: 13, color: InfoColors.lavender)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _Backdrop()),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  children: children,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF07060C), InfoColors.deepPurple, Color(0xFF07060C)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(children: [
        _glow(const Alignment(-1.2, -1.0), AppTheme.accent, 340),
        _glow(const Alignment(1.3, -0.2), AppTheme.pink, 260),
        _glow(const Alignment(-0.8, 1.1), AppTheme.accent, 280),
      ]),
    );
  }

  Widget _glow(Alignment at, Color color, double size) => Align(
        alignment: at,
        child: IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ),
      );
}

/// Frosted glass card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlight;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: highlight
                  ? [AppTheme.accent.withValues(alpha: 0.22), AppTheme.pink.withValues(alpha: 0.10)]
                  : [InfoColors.glassFill, const Color(0x08FFFFFF)],
            ),
            border: Border.all(
              color: highlight ? AppTheme.accent.withValues(alpha: 0.5) : InfoColors.glassBorder,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Icon in a gradient circle with a soft violet glow.
class GlowIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool muted;
  const GlowIcon(this.icon, {super.key, this.size = 44, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: muted ? null : InfoColors.brand,
        color: muted ? Colors.white.withValues(alpha: 0.06) : null,
        border: muted ? Border.all(color: InfoColors.glassBorder) : null,
        boxShadow: muted
            ? null
            : [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.55), blurRadius: size * 0.45)],
      ),
      child: Icon(icon, color: muted ? AppTheme.textMuted : Colors.white, size: size * 0.48),
    );
  }
}

/// Primary rounded gradient button with a built-in loading state.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || loading ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: InfoColors.brand,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [BoxShadow(color: AppTheme.pink.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 8))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.orbitron(size: 12, weight: FontWeight.w700, letterSpacing: 1)),
                        ),
                      ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary outlined pill button.
class GlowOutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const GlowOutlineButton({super.key, required this.label, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: enabled ? InfoColors.lavender : AppTheme.textMuted),
      label: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.inter(
              size: 13, weight: FontWeight.w600, color: enabled ? InfoColors.lavender : AppTheme.textMuted)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        side: BorderSide(color: enabled ? AppTheme.accent.withValues(alpha: 0.7) : InfoColors.glassBorder),
        backgroundColor: enabled ? AppTheme.accent.withValues(alpha: 0.10) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// Eyebrow + title used above every section.
class InfoSectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  const InfoSectionHeading({super.key, required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow,
              style: AppTheme.inter(size: 11, weight: FontWeight.w700, color: AppTheme.pink)
                  .copyWith(letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(title, style: AppTheme.orbitron(size: 18, weight: FontWeight.w800, color: InfoColors.lavender)),
        ],
      ),
    );
  }
}

/// Fades and slides its child in after [delay] — used to stagger sections.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOut,
      opacity: _shown ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        offset: _shown ? Offset.zero : const Offset(0, 0.06),
        child: widget.child,
      ),
    );
  }
}

/// Lays children out in 1–3 equal columns: as many as fit at
/// [minItemWidth] each, so small cards (team) pair up on phones while
/// text-heavy ones (features) get the full width.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double minItemWidth;
  const ResponsiveGrid({super.key, required this.children, this.spacing = 14, this.minItemWidth = 200});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = ((c.maxWidth + spacing) / (minItemWidth + spacing)).floor().clamp(1, 3);
      final itemWidth = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final w in children) SizedBox(width: itemWidth, child: w)],
      );
    });
  }
}

/// Opens an external link (maps, mail, phone) and explains a failure
/// instead of failing silently.
Future<void> openExternal(BuildContext context, Uri uri, String failMessage) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {}
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failMessage)));
  }
}
