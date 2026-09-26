import 'package:flutter/material.dart';
import '../../models/onboarding_slide.dart';
import '../../services/first_run_service.dart';
import '../../services/notification_service.dart';
import '../../services/onboarding_slide_service.dart';
import '../../theme/app_theme.dart';
import '../home/fan_home_screen.dart';
import 'onboarding_screen.dart';

/// Replaces the current route with the pre-login interest + badge step, the
/// last part of the first-run sequence. Completing it stores the selection
/// on-device, marks first-run done, then lands on the guest Home.
void openPreLoginInterestSelection(BuildContext context) {
  final navigator = Navigator.of(context);
  navigator.pushReplacement(
    MaterialPageRoute(builder: (_) => preLoginInterestSelection(navigator)),
  );
}

Widget preLoginInterestSelection(NavigatorState navigator) =>
    OnboardingScreen.preLogin(
      onPreLoginComplete: (categories, badge) async {
        await FirstRunService.instance.completeOnboarding(categories, badge);
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const FanHomeScreen()),
        );
        NotificationService.instance.maybeAskOnce();
      },
    );

/// First-launch intro carousel of admin-managed slides (collection
/// `onboarding_slides`, in `order`). Not to be confused with OnboardingScreen,
/// the interest + badge step that follows it.
class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() => _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  static const List<List<Color>> _placeholderGradients = [
    [AppTheme.accent, AppTheme.cyan],
    [AppTheme.cyan, AppTheme.pink],
    [AppTheme.pink, AppTheme.orange],
  ];

  late final Stream<List<OnboardingSlide>> _slidesStream =
      OnboardingSlideService.instance.watchSlides();
  final PageController _controller = PageController();
  int _index = 0;
  bool _leaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    if (_leaving) return;
    _leaving = true;
    openPreLoginInterestSelection(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: StreamBuilder<List<OnboardingSlide>>(
          stream: _slidesStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _continue());
              return const SizedBox.shrink();
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
              );
            }
            final slides = snapshot.data!;
            if (slides.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _continue());
              return const SizedBox.shrink();
            }
            final index = _index.clamp(0, slides.length - 1);
            final isLast = index == slides.length - 1;
            return Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: isLast
                        ? null
                        : TextButton(
                            onPressed: _continue,
                            child: Text('Skip',
                                style: AppTheme.inter(
                                    size: 13, color: Colors.grey, weight: FontWeight.w600)),
                          ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _pageBody(slides[i], i),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: index == i ? 18 : 6,
                      decoration: BoxDecoration(
                        color: index == i ? AppTheme.cyan : AppTheme.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLast
                          ? _continue
                          : () => _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLast ? AppTheme.accent : AppTheme.cyan,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        isLast ? 'GET STARTED' : 'NEXT',
                        style: AppTheme.orbitron(
                          size: 12,
                          color: isLast ? Colors.white : Colors.black,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pageBody(OnboardingSlide slide, int i) {
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: slide.imageUrl.isNotEmpty
                      ? Image.network(
                          slide.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, st) => _placeholder(i),
                        )
                      : _placeholder(i),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTheme.orbitron(size: 18, weight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: AppTheme.inter(size: 13, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(int i) {
    final colors = _placeholderGradients[i % _placeholderGradients.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.map((c) => c.withValues(alpha: 0.35)).toList(),
        ),
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(28),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Colors.white70, size: 96),
    );
  }
}
