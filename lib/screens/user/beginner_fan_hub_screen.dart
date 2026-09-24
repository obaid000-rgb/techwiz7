import 'package:flutter/material.dart';
import 'glossary_screen.dart';

class BeginnerFanHubScreen extends StatelessWidget {
  const BeginnerFanHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beginner Fan Hub')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'New here? Start your fandom journey.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
          const SizedBox(height: 20),
          _HubCard(
            icon: Icons.menu_book_outlined,
            title: 'Glossary',
            subtitle: 'Learn the terms every fan should know',
            color: const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlossaryScreen()),
              );
            },
          ),
          const SizedBox(height: 14),
          _HubCard(
            icon: Icons.article_outlined,
            title: 'Starter Stories',
            subtitle: 'Beginner-friendly fandom stories',
            color: const Color(0xFF10B981),
            comingSoonPhase: 'Phase 3 (next update)',
          ),
          const SizedBox(height: 14),
          _HubCard(
            icon: Icons.person_search_outlined,
            title: 'Popular Profiles',
            subtitle: 'Meet the characters and figures fans love',
            color: const Color(0xFFF59E0B),
            comingSoonPhase: 'Phase 3 (next update)',
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final String? comingSoonPhase;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.comingSoonPhase,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: isEnabled
          ? onTap
          : () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coming in $comingSoonPhase.')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF16161F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(isEnabled ? 0.4 : 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isEnabled ? color : Colors.white24, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isEnabled ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isEnabled ? Colors.white54 : Colors.white24),
          ],
        ),
      ),
    );
  }
}