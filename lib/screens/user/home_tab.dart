import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_category.dart';
import '../../models/post.dart';
import '../../services/category_service.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
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
  final Set<String> _bookmarkedIds = {};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Trending section ──────────────────────────────────────
          SectionHeader(
            icon: Icons.local_fire_department,
            iconColor: AppTheme.orange,
            title: 'TRENDING FANDOMS',
            trailingText: 'Live Feeds',
          ),
          const SizedBox(height: 12),
          const TrendingCarousel(),
          const SizedBox(height: 20),

          // ── Category chips (live from Firestore) ──────────────────
          StreamBuilder<List<AppCategory>>(
            stream: CategoryService.instance.watchCategories(),
            builder: (context, snapshot) {
              final cats = snapshot.data ?? [];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('All Realm', 'all', null),
                    ...cats.map((c) => _chip(c.name, c.key, c.icon)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Lore section header with depth segmented control ──────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book, color: AppTheme.cyan, size: 16),
                  const SizedBox(width: 8),
                  Text('LORE ARCHIVES & MEDIA',
                      style: AppTheme.orbitron(size: 10, letterSpacing: 0.8)),
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

          // ── Lore cards (live from Firestore) ─────────────────────
          StreamBuilder<List<Post>>(
            stream: PostService.instance.watchPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.grey, size: 28),
                        const SizedBox(height: 8),
                        Text('Could not load lore archives',
                            style: AppTheme.inter(size: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              final allPosts = snapshot.data ?? [];
              final q = widget.searchQuery.toLowerCase();
              final filtered = allPosts.where((p) {
                final matchesCategory =
                    _selectedCategory == 'all' || p.category == _selectedCategory;
                final matchesSearch = q.isEmpty ||
                    p.title.toLowerCase().contains(q) ||
                    p.content.toLowerCase().contains(q);
                return matchesCategory && matchesSearch;
              }).toList();

              if (allPosts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book_outlined, color: Colors.grey, size: 36),
                        const SizedBox(height: 10),
                        Text('No lore archives yet',
                            style: AppTheme.orbitron(
                                size: 12, color: Colors.grey, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Check back soon when new content is published.',
                            style: AppTheme.inter(size: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, color: Colors.grey, size: 36),
                        const SizedBox(height: 10),
                        Text('No results for this filter',
                            style: AppTheme.orbitron(
                                size: 12, color: Colors.grey, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedCategory = 'all';
                            _activeDepth = 'all';
                          }),
                          child: Text('Clear filters',
                              style: AppTheme.inter(size: 11, color: AppTheme.cyan)),
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
                itemBuilder: (context, idx) => _loreCard(context, filtered[idx]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, IconData? icon) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.border),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.35), blurRadius: 8)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? Colors.white : Colors.grey),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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

  Widget _loreCard(BuildContext context, Post post) {
    final isBookmarked = _bookmarkedIds.contains(post.id);
    final badge = post.category.isEmpty ? 'LORE ARCHIVE' : post.category.toUpperCase();
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: post.imageUrl.isNotEmpty
                    ? Image.network(
                        post.imageUrl,
                        height: 144,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, st) => Container(
                          height: 144,
                          color: AppTheme.bg,
                          alignment: Alignment.center,
                          child: const Icon(
                              Icons.article_outlined, color: Colors.white12, size: 36),
                        ),
                      )
                    : Container(
                        height: 144,
                        color: AppTheme.bg,
                        alignment: Alignment.center,
                        child: const Icon(
                            Icons.article_outlined, color: Colors.white12, size: 36),
                      ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.orbitron(
                        color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() {
                    isBookmarked
                        ? _bookmarkedIds.remove(post.id)
                        : _bookmarkedIds.add(post.id);
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isBookmarked
                          ? AppTheme.cyan
                          : Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? Colors.black : Colors.white,
                      size: 16,
                    ),
                  ),
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
                  style: AppTheme.orbitron(size: 13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  post.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(size: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, color: Colors.grey, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          post.category.toUpperCase(),
                          style: AppTheme.inter(size: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FandomDetailScreen(post: post)),
                      ),
                      child: Row(
                        children: [
                          Text('Read Archive',
                              style: AppTheme.inter(
                                  size: 12,
                                  color: AppTheme.cyan,
                                  weight: FontWeight.w600)),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward, size: 13, color: AppTheme.cyan),
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
