import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/category_service.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/fandom_heart_button.dart';
import '../../widgets/lore_card.dart';
import '../../widgets/trending_badge.dart';
import 'widgets/trending_carousel.dart';
import '../explore/category_detail_screen.dart';
import '../explore/fandom_detail_screen.dart';

class HomeTab extends StatefulWidget {
  final String searchQuery;
  const HomeTab({super.key, this.searchQuery = ''});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedCategory = 'all';
  String _activeDepth = 'all';

  late final Stream<List<AppCategory>> _categories =
      CategoryService.instance.watchActiveCategories();
  late final Stream<List<Post>> _posts = PostService.instance.watchActivePosts();

  Future<void> _toggleBookmark(String postId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log in to bookmark posts.')),
      );
      return;
    }
    final wasSaved = user.bookmarkedPostIds.contains(postId);
    final ids = List<String>.from(user.bookmarkedPostIds);
    wasSaved ? ids.remove(postId) : ids.add(postId);
    AuthService.instance.userNotifier.value = user.copyWith(bookmarkedPostIds: ids);
    try {
      await UserService.instance.setBookmarked(user.uid, postId, !wasSaved);
    } catch (e) {
      debugPrint('Bookmark update failed: $e');
      final current = AuthService.instance.currentUser;
      if (current != null) {
        final reverted = List<String>.from(current.bookmarkedPostIds);
        wasSaved ? reverted.add(postId) : reverted.remove(postId);
        AuthService.instance.userNotifier.value =
            current.copyWith(bookmarkedPostIds: reverted.toSet().toList());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update bookmarks. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCategory>>(
      stream: _categories,
      builder: (context, catSnap) {
        final cats = List<AppCategory>.from(catSnap.data ?? [])
          ..sort((a, b) => a.order.compareTo(b.order));
        final catNames = {for (final c in cats) c.key: c.name};

        return StreamBuilder<List<Post>>(
          stream: _posts,
          builder: (context, postSnap) {
            final allPosts = postSnap.data ?? [];
            final counts = <String, int>{};
            for (final p in allPosts) {
              counts[p.category] = (counts[p.category] ?? 0) + 1;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                // Admin-curated slider stays on top.
                const TrendingCarousel(),
                const SizedBox(height: 28),

                if (cats.isNotEmpty) ...[
                  _sectionTitle('FEATURED FANDOMS', 'Tap a fandom to see all its posts'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: cats.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) =>
                          _fandomCard(cats[i], counts[cats[i].key] ?? 0),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                _sectionTitle('LATEST POSTS', 'Pick a fandom or reading level to narrow the list'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      _chip('All', 'all'),
                      for (final c in cats) _chip(c.name, c.key),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _levelToggle(),
                const SizedBox(height: 16),
                ..._postList(postSnap, allPosts, catNames),
              ],
            );
          },
        );
      },
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.orbitron(size: 13, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
        ],
      );

  Widget _fandomCard(AppCategory cat, int postCount) {
    final hasImage = cat.imageUrl != null && cat.imageUrl!.isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
      ),
      child: Container(
        width: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(cat.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (ctx, e, st) => _imageFallback())
            else
              _imageFallback(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xF20D0E15)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: FandomHeartButton(categoryKey: cat.key, categoryName: cat.name),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('$postCount post${postCount == 1 ? '' : 's'}',
                      style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: const Color(0xFF1C1E2E),
        alignment: Alignment.center,
        child: const Icon(Icons.auto_awesome_outlined, color: Colors.white24, size: 32),
      );

  Widget _chip(String label, String value) {
    final on = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppTheme.accent : AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? AppTheme.accent : AppTheme.border),
          ),
          child: Text(label,
              style: AppTheme.inter(
                  size: 13,
                  weight: FontWeight.w600,
                  color: on ? Colors.white : AppTheme.textSecondary)),
        ),
      ),
    );
  }

  Widget _levelToggle() {
    Widget seg(String label, String value) {
      final on = _activeDepth == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _activeDepth = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppTheme.border : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                style: AppTheme.inter(
                    size: 13,
                    weight: FontWeight.w600,
                    color: on ? Colors.white : AppTheme.textMuted)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        seg('All levels', 'all'),
        seg('Beginner', 'beginner'),
        seg('Expert', 'deep'),
      ]),
    );
  }

  List<Widget> _postList(
      AsyncSnapshot<List<Post>> snap, List<Post> allPosts, Map<String, String> catNames) {
    if (snap.hasError) {
      debugPrint('Home posts load error: ${snap.error}');
      return [
        _message(Icons.wifi_off, 'Could not load posts',
            'Check your connection and try again.'),
      ];
    }
    if (!snap.hasData) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan)),
        ),
      ];
    }
    if (allPosts.isEmpty) {
      return [
        _message(Icons.menu_book_outlined, 'No posts yet',
            'Check back soon when new content is published.'),
      ];
    }

    final q = widget.searchQuery.trim().toLowerCase();
    final filtered = allPosts.where((p) {
      if (q.isNotEmpty &&
          !p.title.toLowerCase().contains(q) &&
          !p.content.toLowerCase().contains(q)) {
        return false;
      }
      if (_activeDepth != 'all' && p.contentDepth != _activeDepth) return false;
      return _selectedCategory == 'all' || p.category == _selectedCategory;
    }).toList();

    if (filtered.isEmpty) {
      return [
        _message(
          Icons.search_off,
          q.isNotEmpty ? 'No posts match "${widget.searchQuery.trim()}"' : 'No posts for this filter',
          'Try another fandom or reading level.',
          action: 'Clear filters',
          onAction: () => setState(() {
            _selectedCategory = 'all';
            _activeDepth = 'all';
          }),
        ),
      ];
    }
    return [for (final p in filtered) _postRow(p, catNames[p.category] ?? p.category)];
  }

  Widget _postRow(Post post, String fandomName) {
    final level = switch (post.contentDepth) {
      'beginner' => 'Beginner',
      'deep' => 'Expert',
      _ => post.contentType,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FandomDetailScreen(post: post)),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: PostMediaThumbnail(post: post, height: 84, playIconSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrendingBadge(postId: post.id, margin: const EdgeInsets.only(bottom: 6)),
                      Text(
                        fandomName.isEmpty ? level : '$fandomName · $level',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 11, weight: FontWeight.w600, color: AppTheme.cyan),
                      ),
                      const SizedBox(height: 5),
                      Text(post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 14, weight: FontWeight.w600, height: 1.3)),
                      const SizedBox(height: 5),
                      Text(_relativeDate(post.createdAt),
                          style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                _bookmarkButton(post.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookmarkButton(String postId) => ValueListenableBuilder<UserData?>(
        valueListenable: AuthService.instance.userNotifier,
        builder: (context, user, _) {
          final saved = user?.bookmarkedPostIds.contains(postId) ?? false;
          return SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              tooltip: saved ? 'Remove bookmark' : 'Bookmark',
              onPressed: () => _toggleBookmark(postId),
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                  color: saved ? AppTheme.cyan : AppTheme.textSecondary, size: 22),
            ),
          );
        },
      );

  Widget _message(IconData icon, String title, String subtitle,
          {String? action, VoidCallback? onAction}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.textMuted, size: 36),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTheme.inter(size: 15, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
            if (action != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onAction,
                child: Text(action,
                    style: AppTheme.inter(size: 14, weight: FontWeight.w600, color: AppTheme.cyan)),
              ),
            ],
          ],
        ),
      );

  static String _relativeDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Just now';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}
