import 'package:flutter/material.dart';
import '../models/app_category.dart';
import '../screens/user/category_detail_screen.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';

class TrendingCarousel extends StatefulWidget {
  const TrendingCarousel({super.key});

  @override
  State<TrendingCarousel> createState() => _TrendingCarouselState();
}

class _TrendingCarouselState extends State<TrendingCarousel> {
  final PageController _pageController = PageController();
  // Cached once — calling watchActiveCategories() fresh inside build() would
  // hand StreamBuilder a brand-new stream on every setState() (e.g. from
  // onPageChanged), forcing it through ConnectionState.waiting and remounting
  // the PageView mid-navigation, which snapped the page back to 0.
  late final Stream<List<AppCategory>> _categoriesStream =
      CategoryService.instance.watchActiveCategories();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index, int total) {
    final wrapped = ((index % total) + total) % total;
    _pageController.animateToPage(
      wrapped,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCategory>>(
      stream: _categoriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
            ),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.grey, size: 28),
                  const SizedBox(height: 8),
                  Text('Could not load categories',
                      style: AppTheme.inter(size: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final cats = (snapshot.data ?? [])
            .where((c) => c.isFeaturedInCarousel)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        if (cats.isEmpty) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.category_outlined, color: Colors.grey, size: 28),
                  const SizedBox(height: 8),
                  Text('No categories featured yet',
                      style: AppTheme.inter(size: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    itemCount: cats.length,
                    itemBuilder: (context, index) => _SlideCard(cat: cats[index]),
                  ),
                  _NavArrow(
                    alignment: Alignment.centerLeft,
                    icon: Icons.chevron_left,
                    onTap: () => _goTo(_currentIndex - 1, cats.length),
                  ),
                  _NavArrow(
                    alignment: Alignment.centerRight,
                    icon: Icons.chevron_right,
                    onTap: () => _goTo(_currentIndex + 1, cats.length),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                cats.length,
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
      },
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.cat});

  final AppCategory cat;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
      ),
      child: Container(
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
            if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty)
              Image.network(
                cat.imageUrl!,
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
              )
            else
              Container(
                color: AppTheme.card,
                alignment: Alignment.center,
                child: const Icon(Icons.category_outlined, color: Colors.white12, size: 40),
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
                  Text(
                    cat.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (cat.description.isNotEmpty)
                    Text(
                      cat.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
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
