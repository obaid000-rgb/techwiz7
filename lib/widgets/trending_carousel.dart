import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TrendingCarousel extends StatefulWidget {
  const TrendingCarousel({super.key});

  @override
  State<TrendingCarousel> createState() => _TrendingCarouselState();
}

class _TrendingCarouselState extends State<TrendingCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> slides = [
    {
      'tag': 'ANIME & MANGA',
      'title': 'Neon Genesis: Cyber Rebirth',
      'desc': 'Episode 12 breakdown & official lore archives released.',
      'img': 'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=600&q=80',
    },
    {
      'tag': 'GAMING & ESPORTS',
      'title': 'Cyberpunk 2088 Championship',
      'desc': 'Grand finals live stream bracket & meta breakdown.',
      'img': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=600&q=80',
    },
    {
      'tag': 'SCI-FI ARCHIVES',
      'title': 'Interstellar Odyssey Universe',
      'desc': 'Full beginner timeline and deep dive ship schematics.',
      'img': 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?auto=format&fit=crop&w=600&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final item = slides[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                  image: DecorationImage(
                    image: NetworkImage(item['img']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppTheme.bg.withOpacity(0.95),
                        AppTheme.bg.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item['tag']!,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['title']!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        item['desc']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slides.length,
                (idx) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentIndex == idx ? 18 : 6,
              decoration: BoxDecoration(
                color: _currentIndex == idx ? AppTheme.cyan : AppTheme.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}