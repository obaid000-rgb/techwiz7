import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lore_card.dart';
import '../../widgets/trending_badge.dart';
import 'beginner_fan_hub_screen.dart';
import 'deep_dive_screen.dart';
import 'fandom_detail_screen.dart';
import 'glossary_screen.dart';
import 'post_list_screen.dart';

/// Lore tab: Today's Fandom highlight, "where to start" entry tiles
/// (Beginner Hub, Deep Dive, Glossary, Latest) and content-type shortcuts.
class LoreTab extends StatefulWidget {
  const LoreTab({super.key});

  @override
  State<LoreTab> createState() => _LoreTabState();
}

class _LoreTabState extends State<LoreTab> {
  late final Stream<List<Post>> _posts = PostService.instance.watchActivePosts();
  late final Stream<Post?> _today = PostService.instance.watchFandomOfTheDay();

  static const _types = [
    _TypeInfo('News', Icons.article_outlined, AppTheme.cyan),
    _TypeInfo('Gallery', Icons.photo_library_outlined, AppTheme.orange),
    _TypeInfo('Video', Icons.play_circle_outline, AppTheme.pink),
    _TypeInfo('Podcast', Icons.mic_none_rounded, AppTheme.accent),
  ];

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: _posts,
      builder: (context, snap) {
        final posts = snap.data;
        int count(bool Function(Post) test) => posts?.where(test).length ?? 0;
        String label(int n, String unit) =>
            posts == null ? '' : '$n $unit${n == 1 ? '' : 's'}';

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Text('Lore', style: AppTheme.orbitron(size: 22, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Stories, guides and deep dives on your fandoms.',
                style: AppTheme.inter(size: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            _todaysFandom(),
            const SizedBox(height: 28),
            Text('WHERE DO YOU WANT TO START?', style: AppTheme.orbitron(size: 13, letterSpacing: 1)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _tile(Icons.school_outlined, AppTheme.cyan, 'New fan?',
                    'Easy intros to start any fandom',
                    label(count((p) => p.contentDepth == 'beginner'), 'post'),
                    () => _push(const BeginnerFanHubScreen())),
                _tile(Icons.scuba_diving_outlined, AppTheme.accent, 'Deep Dive',
                    'Trivia, theories and interviews',
                    label(count((p) => p.contentDepth == 'deep'), 'post'),
                    () => _push(const DeepDiveScreen())),
                _tile(Icons.menu_book_outlined, AppTheme.orange, 'Glossary',
                    'Fan words explained simply', '',
                    () => _push(const GlossaryScreen())),
                _tile(Icons.new_releases_outlined, AppTheme.pink, 'Latest',
                    'Everything posted recently',
                    label(posts?.length ?? 0, 'post'),
                    () => _push(PostListScreen(
                          title: 'Latest Posts',
                          stream: PostService.instance.watchActivePosts(),
                        ))),
              ],
            ),
            const SizedBox(height: 28),
            Text('BROWSE BY TYPE', style: AppTheme.orbitron(size: 13, letterSpacing: 1)),
            const SizedBox(height: 12),
            for (final t in _types)
              _typeRow(t, label(count((p) => p.contentType == t.label), 'post')),
          ],
        );
      },
    );
  }

  Widget _todaysFandom() => StreamBuilder<Post?>(
        stream: _today,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)),
            );
          }
          final post = snap.data;
          if (post == null) {
            return _card(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                const Icon(Icons.star_border_rounded, color: AppTheme.textMuted, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('No fandom highlighted today. Check back tomorrow.',
                      style: AppTheme.inter(size: 13, color: AppTheme.textSecondary)),
                ),
              ]),
            );
          }
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(children: [
                  PostMediaThumbnail(post: post, height: 160, playIconSize: 44),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppTheme.orange, borderRadius: BorderRadius.circular(14)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text("Today's Fandom",
                            style: AppTheme.inter(size: 11, weight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                  Positioned(top: 12, right: 12, child: TrendingBadge(postId: post.id)),
                ]),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.title,
                          style: AppTheme.inter(size: 17, weight: FontWeight.w700, height: 1.3)),
                      const SizedBox(height: 6),
                      Text(post.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 13, color: AppTheme.textSecondary, height: 1.5)),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => _push(FandomDetailScreen(post: post)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cyan,
                            foregroundColor: AppTheme.bg,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Read now',
                              style: AppTheme.inter(size: 14, weight: FontWeight.w700, color: AppTheme.bg)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _tile(IconData icon, Color color, String title, String sub, String meta,
          VoidCallback onTap) =>
      Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                Text(title, style: AppTheme.inter(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(size: 12, color: AppTheme.textMuted, height: 1.35)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta, style: AppTheme.inter(size: 11, weight: FontWeight.w600, color: color)),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _typeRow(_TypeInfo t, String meta) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _push(PostListScreen(
              title: t.label,
              stream: PostService.instance.watchPostsByContentType(t.label),
              emptyMessage: 'No ${t.label} posts yet.',
            )),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
                Icon(t.icon, color: t.color, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(t.label, style: AppTheme.inter(size: 14, weight: FontWeight.w500))),
                Text(meta, style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
              ]),
            ),
          ),
        ),
      );

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: child,
      );
}

class _TypeInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _TypeInfo(this.label, this.icon, this.color);
}
