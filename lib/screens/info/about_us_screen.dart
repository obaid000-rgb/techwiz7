import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_info.dart';
import '../../theme/app_theme.dart';
import 'contact_us_screen.dart';
import 'widgets/info_ui.dart';

/// About Us: brand hero, story, what the app does, mission, team, closing.
/// All organisation-specific text comes from [AppInfo].
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const _features = [
    (Icons.auto_stories_outlined, 'Lore & Deep Dives',
        'Beginner guides, expert deep dives, a fandom glossary and a daily featured fandom.'),
    (Icons.event_outlined, 'Events Near You',
        'Conventions and meetups sorted by distance, on a map, or in a calendar.'),
    (Icons.storefront_outlined, 'Official Merch',
        'Browse by category, sort by price, and check out in a simulated store.'),
    (Icons.notifications_active_outlined, 'Price Alerts',
        'Wishlist an item and get notified when its price goes up or down.'),
    (Icons.download_for_offline_outlined, 'Read Offline',
        'Save posts to your phone and read them without a connection.'),
    (Icons.smart_toy_outlined, 'AI Help',
        'An in-app assistant that explains how every feature works.'),
  ];

  @override
  Widget build(BuildContext context) {
    return InfoPageScaffold(
      title: 'About Us',
      children: [
        const FadeSlideIn(child: _Hero()),
        const SizedBox(height: 32),

        FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const InfoSectionHeading(eyebrow: 'WHO WE ARE', title: 'Our Story'),
            GlassCard(
              child: Text(AppInfo.story,
                  style: AppTheme.inter(size: 15, color: AppTheme.textSecondary, height: 1.65)),
            ),
          ]),
        ),
        const SizedBox(height: 32),

        FadeSlideIn(
          delay: const Duration(milliseconds: 220),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const InfoSectionHeading(eyebrow: 'INSIDE THE APP', title: 'What We Do'),
            ResponsiveGrid(children: [
              for (final f in _features) _FeatureCard(icon: f.$1, title: f.$2, body: f.$3),
            ]),
          ]),
        ),
        const SizedBox(height: 32),

        FadeSlideIn(
          delay: const Duration(milliseconds: 320),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const InfoSectionHeading(eyebrow: 'WHY WE BUILD', title: 'Our Mission'),
            GlassCard(
              highlight: true,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GlowIcon(Icons.format_quote_rounded, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(AppInfo.mission,
                      style: AppTheme.inter(size: 16, weight: FontWeight.w500, color: InfoColors.lavender, height: 1.6)),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 32),

        FadeSlideIn(
          delay: const Duration(milliseconds: 420),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const InfoSectionHeading(eyebrow: 'THE PEOPLE', title: 'Meet the Team'),
            ResponsiveGrid(minItemWidth: 140, children: [for (final m in AppInfo.team) _TeamCard(member: m)]),
          ]),
        ),
        const SizedBox(height: 32),

        const FadeSlideIn(delay: Duration(milliseconds: 520), child: _Closing()),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accent.withValues(alpha: 0.35), InfoColors.deepPurple, AppTheme.pink.withValues(alpha: 0.22)],
        ),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.45)),
        boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.25), blurRadius: 40)],
      ),
      child: Column(
        children: [
          // Same logo mark as the app's top bar.
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppTheme.accent, AppTheme.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.6), blurRadius: 30)],
            ),
            alignment: Alignment.center,
            child: Text('F',
                style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 38)),
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.cyan, AppTheme.accent, AppTheme.pink],
              ).createShader(bounds),
              child: Text(AppInfo.appName.toUpperCase(),
                  style: GoogleFonts.orbitron(
                      color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30, letterSpacing: 3)),
            ),
          ),
          const SizedBox(height: 4),
          Text(AppInfo.edition.toUpperCase(),
              style: GoogleFonts.orbitron(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 4)),
          const SizedBox(height: 18),
          Text(AppInfo.tagline,
              textAlign: TextAlign.center,
              style: AppTheme.inter(size: 16, weight: FontWeight.w500, color: InfoColors.lavender, height: 1.5)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _FeatureCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlowIcon(icon, size: 42),
        const SizedBox(height: 14),
        Text(title, style: AppTheme.inter(size: 15, weight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 6),
        Text(body, style: AppTheme.inter(size: 13, color: AppTheme.textSecondary, height: 1.5)),
      ]),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamMember member;
  const _TeamCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final initial = member.name.trim().isEmpty ? '?' : member.name.trim()[0].toUpperCase();
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: InfoColors.brand,
            boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.45), blurRadius: 18)],
          ),
          child: CircleAvatar(
            radius: 34,
            backgroundColor: InfoColors.deepPurple,
            backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
            child: member.photoUrl == null
                ? Text(initial, style: AppTheme.orbitron(size: 22, weight: FontWeight.w900, color: InfoColors.lavender))
                : null,
          ),
        ),
        const SizedBox(height: 14),
        Text(member.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.inter(size: 15, weight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        Text(member.role,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.inter(size: 12, weight: FontWeight.w600, color: AppTheme.pink)),
      ]),
    );
  }
}

class _Closing extends StatelessWidget {
  const _Closing();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      highlight: true,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      child: Column(children: [
        const GlowIcon(Icons.favorite_rounded, size: 50),
        const SizedBox(height: 16),
        Text('Made for fans, by fans.',
            textAlign: TextAlign.center,
            style: AppTheme.orbitron(size: 17, weight: FontWeight.w800, color: InfoColors.lavender)),
        const SizedBox(height: 8),
        Text('Questions, ideas or feedback? We\'d love to hear from you.',
            textAlign: TextAlign.center,
            style: AppTheme.inter(size: 14, color: AppTheme.textSecondary, height: 1.5)),
        const SizedBox(height: 20),
        GradientButton(
          label: 'CONTACT US',
          icon: Icons.mail_outline_rounded,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactUsScreen()),
          ),
        ),
        const SizedBox(height: 18),
        Text('${AppInfo.appName} · ${AppInfo.edition}',
            style: AppTheme.inter(size: 11, color: AppTheme.textMuted)),
      ]),
    );
  }
}
