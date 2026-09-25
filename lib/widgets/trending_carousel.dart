import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TrendingCarousel extends StatefulWidget {
  const TrendingCarousel({super.key});

  @override
  State<TrendingCarousel> createState() => _TrendingCarouselState();
}

class _TrendingCarouselState extends State<TrendingCarousel> {
  final PageController _pageController =  PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> slides = [
    {
      'tag': 'ANIME & MANGA',
      'title': 'Neon Genesis: Cyber Rebirth',
      'desc': 'Episode 12 breakdown & official lore archives released.',
      'img':
          'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=600&q=80',
    },
    {
      'tag': 'GAMING & ESPORTS',
      'title': 'Cyberpunk 2088 Championship',
      'desc': 'Grand finals live stream bracket & meta breakdown.',
      'img':
          'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=600&q=80',
    },
    {
      'tag': 'SCI-FI ARCHIVES',
      'title': 'Interstellar Odyssey Universe',
      'desc': 'Full beginner timeline and deep dive ship schematics.',
      'img':
          'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?auto=format&fit=crop&w=600&q=80',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    final total = slides.length;
    final wrapped = ((index % total) + total) % total;
    _pageController.animateToPage(
      wrapped,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (slides.isEmpty) return const SizedBox(height: 180);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemCount: slides.length,
                itemBuilder: (context, index) => _SlideCard(data: slides[index]),
              ),
              _NavArrow(
                alignment: Alignment.centerLeft,
                icon: Icons.chevron_left,
                onTap: () => _goTo(_currentIndex - 1),
              ),
              _NavArrow(
                alignment: Alignment.centerRight,
                icon: Icons.chevron_right,
                onTap: () => _goTo(_currentIndex + 1),
              ),
            ],
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

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.data});

  final Map<String, String> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        color: AppTheme.bg,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            data['img']!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white38,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppTheme.bg,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: Colors.white24,
                size: 32,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppTheme.bg.withValues(alpha: 0.95),
                  AppTheme.bg.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['tag']!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  data['desc']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.alignment,
    required this.icon,
    required this.onTap,
  });

  final Alignment alignment;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: AppTheme.bg.withValues(alpha: 0.7),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}