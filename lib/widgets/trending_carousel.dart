import 'package:flutter/material.dart';

class TrendingCarousel extends StatelessWidget {
  const TrendingCarousel({super.key});

  static const List<_TrendingFandom> _sampleFandoms = [
    _TrendingFandom(name: 'Anime & Manga', color: Color(0xFFEF4444), icon: Icons.movie_filter_outlined),
    _TrendingFandom(name: 'Gaming & Esports', color: Color(0xFF3B82F6), icon: Icons.sports_esports_outlined),
    _TrendingFandom(name: 'Comics', color: Color(0xFFF59E0B), icon: Icons.auto_stories_outlined),
    _TrendingFandom(name: 'K-Pop & Idols', color: Color(0xFFEC4899), icon: Icons.mic_external_on_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _sampleFandoms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final fandom = _sampleFandoms[index];
          return Container(
            width: 150,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fandom.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: fandom.color.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(fandom.icon, color: fandom.color, size: 28),
                const Spacer(),
                Text(fandom.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const Text('Trending now', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrendingFandom {
  final String name;
  final Color color;
  final IconData icon;

  const _TrendingFandom({required this.name, required this.color, required this.icon});
}