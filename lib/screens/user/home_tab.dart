import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/trending_carousel.dart';
import 'beginner_fan_hub_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName!.split(' ').first : 'Fan';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Welcome back, $firstName',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            "Here's what's trending across your fandoms",
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          const TrendingCarousel(),
          const SizedBox(height: 28),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BeginnerFanHubScreen()),
              );
            },
            child: const _SectionCard(
              title: 'Beginner Fan Hub',
              subtitle: 'New here? Start with the Glossary and starter guides',
              icon: Icons.school_outlined,
              enabled: true,
            ),
          ),
          const SizedBox(height: 16),
          const _SectionCard(
            title: 'Latest News & Stories',
            subtitle: 'News, media, and deep-dive content — coming in Phase 3',
            icon: Icons.article_outlined,
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final accent = enabled ? const Color(0xFF8B5CF6) : Colors.white24;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          ),
          if (enabled) const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );
  }
}