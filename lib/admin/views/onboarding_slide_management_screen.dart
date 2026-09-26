import 'package:flutter/material.dart';
import '../../models/onboarding_slide.dart';
import '../../services/onboarding_slide_service.dart';
import '../../theme/app_theme.dart';
import 'onboarding_slide_form_screen.dart';

class OnboardingSlideManagementScreen extends StatelessWidget {
  const OnboardingSlideManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OnboardingSlide>>(
      stream: OnboardingSlideService.instance.watchSlides(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.pink));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: AppTheme.inter(color: Colors.red)));
        }
        final slides = List<OnboardingSlide>.from(snapshot.data ?? [])
          ..sort((a, b) => a.order.compareTo(b.order));
        return Column(
          children: [
            _header(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                  'Shown to new installs before login, top to bottom. Drag to reorder.',
                  style: AppTheme.inter(size: 10, color: Colors.grey)),
            ),
            Expanded(
              child: slides.isEmpty
                  ? _empty()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: slides.length,
                      onReorderItem: (oldIndex, newIndex) {
                        final reordered = List<OnboardingSlide>.from(slides);
                        final moved = reordered.removeAt(oldIndex);
                        reordered.insert(newIndex, moved);
                        OnboardingSlideService.instance.reorderSlides(reordered);
                      },
                      itemBuilder: (context, i) => _slideRow(
                          context, slides[i], i,
                          key: ValueKey(slides[i].id)),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Onboarding Slides', style: AppTheme.orbitron(size: 13)),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OnboardingSlideFormScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pink,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text('ADD', style: AppTheme.orbitron(size: 9)),
            ),
          ],
        ),
      );

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.slideshow_outlined, color: Colors.grey, size: 36),
              const SizedBox(height: 12),
              Text('No onboarding slides yet',
                  style: AppTheme.inter(size: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                  'New installs will skip straight to interest selection. Tap ADD to create one.',
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(size: 11, color: Colors.grey)),
            ],
          ),
        ),
      );

  Widget _slideRow(BuildContext context, OnboardingSlide slide, int index,
          {required Key key}) =>
      Container(
        key: key,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator, color: Colors.grey, size: 18),
            const SizedBox(width: 8),
            _thumb(slide),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slide.title,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppTheme.orbitron(size: 11, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Slide ${index + 1}',
                      style: AppTheme.inter(size: 10, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(slide.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 10, color: Colors.white38)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppTheme.cyan, size: 18),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OnboardingSlideFormScreen(existing: slide)),
              ),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 18),
              onPressed: () => _confirmDelete(context, slide),
              tooltip: 'Delete',
            ),
          ],
        ),
      );

  Widget _thumb(OnboardingSlide slide, {double size = 44}) {
    if (slide.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          slide.imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, e, st) => _thumbFallback(size),
        ),
      );
    }
    return _thumbFallback(size);
  }

  Widget _thumbFallback(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.pink.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined,
            color: AppTheme.pink, size: size * 0.45),
      );

  Future<void> _confirmDelete(
      BuildContext context, OnboardingSlide slide) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${slide.title}"?',
            style: AppTheme.orbitron(size: 12, color: Colors.white)),
        content: Text('This cannot be undone.',
            style: AppTheme.inter(size: 12, color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL',
                style: AppTheme.orbitron(size: 9, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DELETE',
                style: AppTheme.orbitron(size: 9, color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await OnboardingSlideService.instance.deleteSlide(slide.id);
    }
  }
}
