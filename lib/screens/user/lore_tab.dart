import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lore_card.dart';
import '../../widgets/section_header.dart';
import 'fandom_detail_screen.dart';
import 'glossary_screen.dart';
import 'post_list_screen.dart';

/// Lore tab landing page: content-type quick filters, Today's Fandom
/// highlight, and Explore Latest. The Category slider now lives on Home.
class LoreTab extends StatelessWidget {
  const LoreTab({super.key});

  static const List<_ContentTypeFilter> _contentTypeFilters = [
    _ContentTypeFilter('News', Icons.article_outlined, AppTheme.cyan),
    _ContentTypeFilter('Gallery', Icons.photo_library_outlined, AppTheme.orange),
    _ContentTypeFilter('Video', Icons.play_circle_outline, AppTheme.pink),
    _ContentTypeFilter('Podcast', Icons.mic_outlined, AppTheme.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Content-type quick filters ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _contentTypeFilters
                .map((f) => _quickFilterCircle(context, f))
                .toList(),
          ),
          const SizedBox(height: 16),

          // ── Glossary entry point ─────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GlossaryScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, color: AppTheme.cyan, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fandom Glossary',
                            style: AppTheme.inter(
                                size: 13, color: Colors.white, weight: FontWeight.w600)),
                        Text('Look up terms & lingo',
                            style: AppTheme.inter(size: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 13),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Today's Fandom ────────────────────────────────────────
          SectionHeader(
            icon: Icons.star,
            iconColor: AppTheme.accent,
            title: "TODAY'S FANDOM",
          ),
          const SizedBox(height: 12),
          _todaysFandomSection(context),
          const SizedBox(height: 24),

          // ── Explore Latest ────────────────────────────────────────
          SectionHeader(
            icon: Icons.explore_outlined,
            iconColor: AppTheme.cyan,
            title: 'EXPLORE LATEST',
          ),
          const SizedBox(height: 12),
          _exploreLatestSection(context),
        ],
      ),
    );
  }

  Widget _quickFilterCircle(BuildContext context, _ContentTypeFilter filter) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostListScreen(
            title: filter.label,
            stream: PostService.instance.watchPostsByContentType(filter.label),
            emptyMessage: 'No ${filter.label} posts yet.',
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filter.color.withValues(alpha: 0.15),
              border: Border.all(color: filter.color.withValues(alpha: 0.5)),
            ),
            child: Icon(filter.icon, color: filter.color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(filter.label,
              style: AppTheme.inter(size: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _todaysFandomSection(BuildContext context) {
    return StreamBuilder<Post?>(
      stream: PostService.instance.watchFandomOfTheDay(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
            ),
          );
        }
        final post = snapshot.data;
        if (post == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_border, color: Colors.grey, size: 32),
                const SizedBox(height: 8),
                Text('No fandom highlighted today',
                    style: AppTheme.inter(size: 12, color: Colors.grey)),
              ],
            ),
          );
        }
        return _featuredFandomCard(context, post);
      },
    );
  }

  Widget _featuredFandomCard(BuildContext context, Post post) {
    return GestureDetector(
      // A video plays inline via PostMediaThumbnail's own tap handling —
      // don't compete with it for the tap by also navigating away.
      onTap: post.hasVideo
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FandomDetailScreen(post: post)),
              ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PostMediaThumbnail(post: post, height: 220, playIconSize: 48),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.bg.withValues(alpha: 0.95),
                    AppTheme.bg.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text('TODAY\'S FANDOM',
                        style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
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
                  Text(post.title,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(post.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exploreLatestSection(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: PostService.instance.watchActivePosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
            ),
          );
        }
        final latest = (snapshot.data ?? []).take(4).toList();
        if (latest.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            alignment: Alignment.center,
            child: Text('No posts yet',
                style: AppTheme.inter(size: 12, color: Colors.grey)),
          );
        }
        return Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: latest.length,
              itemBuilder: (context, i) => _gridPostCard(context, latest[i]),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostListScreen(
                      title: 'Explore Latest',
                      stream: PostService.instance.watchActivePosts(),
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.cyan),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('SEE ALL',
                    style: AppTheme.orbitron(size: 10, color: AppTheme.cyan)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _gridPostCard(BuildContext context, Post post) {
    return GestureDetector(
      onTap: post.hasVideo
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FandomDetailScreen(post: post)),
              ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PostMediaThumbnail(post: post, playIconSize: 30),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                post.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.inter(size: 11, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentTypeFilter {
  final String label;
  final IconData icon;
  final Color color;
  const _ContentTypeFilter(this.label, this.icon, this.color);
}
