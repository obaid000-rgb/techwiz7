import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_category.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/category_service.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lore_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/trending_carousel.dart';
import 'fandom_detail_screen.dart';

class HomeTab extends StatefulWidget {
  final String searchQuery;
  const HomeTab({super.key, this.searchQuery = ''});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedCategory = 'all';
  String _activeDepth = 'all';

  Future<void> _toggleBookmark(String postId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log in to bookmark posts.')),
      );
      return;
    }
    final ids = List<String>.from(user.bookmarkedPostIds);
    ids.contains(postId) ? ids.remove(postId) : ids.add(postId);
    final updated = user.copyWith(bookmarkedPostIds: ids);
    AuthService.instance.userNotifier.value = updated;
    try {
      await UserService.instance.updateUser(updated);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCategory>>(
      stream: CategoryService.instance.watchActiveCategories(),
      builder: (context, catSnap) {
        final visibleCats = List<AppCategory>.from(catSnap.data ?? [])
          ..sort((a, b) => a.order.compareTo(b.order));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Featured categories ────────────────────────────────────
              SectionHeader(
                icon: Icons.category_outlined,
                iconColor: AppTheme.orange,
                title: 'FEATURED CATEGORIES',
              ),
              const SizedBox(height: 12),
              const TrendingCarousel(),
              const SizedBox(height: 20),

              // ── Category chips ─────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('All Realm', 'all', null),
                    ...visibleCats
                        .map((c) => _chip(c.name, c.key, c.imageUrl)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Lore section header ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book,
                          color: AppTheme.cyan, size: 16),
                      const SizedBox(width: 8),
                      Text('LORE ARCHIVES & MEDIA',
                          style: AppTheme.orbitron(
                              size: 10, letterSpacing: 0.8)),
                    ],
                  ),
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        _depthSegment('All', 'all'),
                        _depthSegment('Beginner', 'beginner'),
                        _depthSegment('Deep', 'deep'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Posts ─────────────────────────────────────────────────
              StreamBuilder<List<Post>>(
                stream: PostService.instance.watchPosts(),
                builder: (context, postSnap) {
                  if (postSnap.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.cyan),
                      ),
                    );
                  }
                  if (postSnap.hasError) {
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off,
                                color: Colors.grey, size: 28),
                            const SizedBox(height: 8),
                            Text('Could not load lore archives',
                                style: AppTheme.inter(
                                    size: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }

                  final allPosts = postSnap.data ?? [];
                  final q = widget.searchQuery.toLowerCase();

                  final filtered = allPosts.where((p) {
                    final matchesSearch = q.isEmpty ||
                        p.title.toLowerCase().contains(q) ||
                        p.content.toLowerCase().contains(q);
                    if (!matchesSearch) return false;

                    // Beginner/Deep only match posts explicitly tagged that
                    // way; untagged posts only show under "All" depth.
                    final matchesDepth =
                        _activeDepth == 'all' || p.contentDepth == _activeDepth;
                    if (!matchesDepth) return false;

                    if (_selectedCategory == 'all') return true;
                    return p.category == _selectedCategory;
                  }).toList();

                  if (allPosts.isEmpty) {
                    return _emptyState(
                      Icons.menu_book_outlined,
                      'No lore archives yet',
                      'Check back soon when new content is published.',
                    );
                  }
                  if (filtered.isEmpty) {
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off,
                                color: Colors.grey, size: 36),
                            const SizedBox(height: 10),
                            Text('No results for this filter',
                                style: AppTheme.orbitron(
                                    size: 12,
                                    color: Colors.grey,
                                    weight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => setState(() {
                                _selectedCategory = 'all';
                                _activeDepth = 'all';
                              }),
                              child: Text('Clear filters',
                                  style: AppTheme.inter(
                                      size: 11,
                                      color: AppTheme.cyan)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) =>
                        _loreCard(context, filtered[idx]),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, String value, String? imageUrl) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppTheme.accent : AppTheme.border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color:
                          AppTheme.accent.withValues(alpha: 0.35),
                      blurRadius: 8)
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              ClipOval(
                child: Image.network(
                  imageUrl,
                  width: 14,
                  height: 14,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, st) =>
                      const SizedBox(width: 14, height: 14),
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTheme.orbitron(
                size: 10,
                color: isSelected ? Colors.white : Colors.grey,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _depthSegment(String label, String value) {
    final isActive = _activeDepth == value;
    return GestureDetector(
      onTap: () => setState(() => _activeDepth = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTheme.orbitron(
            size: 8,
            color: isActive ? Colors.black : Colors.grey,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey, size: 36),
              const SizedBox(height: 10),
              Text(title,
                  style: AppTheme.orbitron(
                      size: 12,
                      color: Colors.grey,
                      weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: AppTheme.inter(size: 11, color: Colors.grey)),
            ],
          ),
        ),
      );

  Widget _loreCard(BuildContext context, Post post) {
    final badge =
        post.category.isEmpty ? 'LORE ARCHIVE' : post.category.toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: PostMediaThumbnail(post: post, height: 144),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: ValueListenableBuilder<UserData?>(
                  valueListenable: AuthService.instance.userNotifier,
                  builder: (context, user, _) {
                    final isBookmarked =
                        user?.bookmarkedPostIds.contains(post.id) ?? false;
                    return GestureDetector(
                      onTap: () => _toggleBookmark(post.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isBookmarked
                              ? AppTheme.cyan
                              : Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: isBookmarked ? Colors.black : Colors.white,
                          size: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.orbitron(
                      size: 13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  post.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(
                      size: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer_outlined,
                            color: Colors.grey, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          post.category.toUpperCase(),
                          style:
                              AppTheme.inter(size: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                FandomDetailScreen(post: post)),
                      ),
                      child: Row(
                        children: [
                          Text('Read Archive',
                              style: AppTheme.inter(
                                  size: 12,
                                  color: AppTheme.cyan,
                                  weight: FontWeight.w600)),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward,
                              size: 13, color: AppTheme.cyan),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
