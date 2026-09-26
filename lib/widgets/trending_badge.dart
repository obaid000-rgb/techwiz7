import 'package:flutter/material.dart';
import '../services/trending_service.dart';
import '../theme/app_theme.dart';

/// "🔥 Trending Today" pill. Renders nothing unless [postId] is the one
/// post currently trending, so it can be dropped into any post card.
class TrendingBadge extends StatelessWidget {
  final String postId;
  /// Spacing applied only when the badge is actually shown.
  final EdgeInsetsGeometry margin;
  const TrendingBadge({super.key, required this.postId, this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    TrendingService.instance.start(); // idempotent; covers any entry point
    return ValueListenableBuilder<String?>(
      valueListenable: TrendingService.instance.trendingPostId,
      builder: (context, id, _) {
        if (id == null || id != postId) return const SizedBox.shrink();
        return Container(
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF97316), AppTheme.pink]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: AppTheme.pink.withValues(alpha: 0.45), blurRadius: 8),
            ],
          ),
          child: Text(
            '🔥 Trending Today',
            maxLines: 1,
            style: AppTheme.inter(size: 10, weight: FontWeight.w800, color: Colors.white),
          ),
        );
      },
    );
  }
}
