import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import 'user/fan_home_screen.dart';

const String kAppPrefsBox = 'app_prefs';
const String kHasSeenOnboardingKey = 'hasSeenOnboarding';

class _IntroPage {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
  const _IntroPage(this.title, this.description, this.icon, this.colors);
}

/// First-launch intro carousel. Shown once per install (see [kHasSeenOnboardingKey]).
/// Not to be confused with OnboardingScreen, which is the post-signup
/// Select Fandoms step.
class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() => _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  static const List<_IntroPage> _pages = [
    // PLACEHOLDER illustration → assets/images/onboarding/onboarding_explore.png (1:1, 1080×1080)
    _IntroPage(
      'Explore Your Fandoms',
      'Dive into lore, news, galleries, videos and podcasts from the worlds you love.',
      Icons.auto_stories_outlined,
      [AppTheme.accent, AppTheme.cyan],
    ),
    // PLACEHOLDER illustration → assets/images/onboarding/onboarding_discover.png (1:1, 1080×1080)
    _IntroPage(
      'Discover New Worlds',
      'Find trending fandoms, beginner guides and deep dives into stories you have yet to meet.',
      Icons.travel_explore,
      [AppTheme.cyan, AppTheme.pink],
    ),
    // PLACEHOLDER illustration → assets/images/onboarding/onboarding_community.png (1:1, 1080×1080)
    _IntroPage(
      'Be Part of the Community',
      'Catch conventions near you, collect official merch and save your favourites.',
      Icons.groups_outlined,
      [AppTheme.pink, AppTheme.orange],
    ),
  ];

  final PageController _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      final prefs = await Hive.openBox(kAppPrefsBox);
      await prefs.put(kHasSeenOnboardingKey, true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FanHomeScreen()),
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: _isLast
                    ? null
                    : TextButton(
                        onPressed: _finishing ? null : _finish,
                        child: Text('Skip',
                            style: AppTheme.inter(
                                size: 13, color: Colors.grey, weight: FontWeight.w600)),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _pageBody(_pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: _index == i ? 18 : 6,
                  decoration: BoxDecoration(
                    color: _index == i ? AppTheme.cyan : AppTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finishing ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLast ? AppTheme.accent : AppTheme.cyan,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _isLast ? 'GET STARTED' : 'NEXT',
                    style: AppTheme.orbitron(
                      size: 12,
                      color: _isLast ? Colors.white : Colors.black,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageBody(_IntroPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: page.colors
                          .map((c) => c.withValues(alpha: 0.35))
                          .toList(),
                    ),
                    border: Border.all(color: AppTheme.border),
                  ),
                  alignment: Alignment.center,
                  child: Icon(page.icon, color: Colors.white70, size: 96),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTheme.orbitron(size: 18, weight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: AppTheme.inter(size: 13, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
