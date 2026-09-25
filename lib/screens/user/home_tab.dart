import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_category.dart';
import '../../models/fandom.dart';
import '../../services/category_service.dart';
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
  final Set<int> _bookmarkedIds = {};
  late Future<List<AppCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CategoryService.instance.fetchCategories();
  }

  final List<Fandom> loreList = [
    Fandom(
      id: 1,
      title: "Cyberpunk 2088: The Arasaka Vault Heist",
      category: "gaming",
      depth: "deep",
      badge: "EPISODE LORE",
      img: "https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=500&q=80",
      summary: "Complete breakdown of the legendary netrunner infiltration into orbital vault.",
      fullBody:
          "The Arasaka Vault Heist remains the most pivotal event in 2088 netrunning history. Executed by a rogue squad of Mercs, the operation breached three layers of security to retrieve the mythical Soulkiller 2.0 source code. This archive details step-by-step IC breaching and ICE protection protocols.",
    ),
    Fandom(
      id: 2,
      title: "Demon Slayer: Breath of Cyber-Flame",
      category: "anime",
      depth: "beginner",
      badge: "BEGINNER GUIDE",
      img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=500&q=80",
      summary: "An introductory timeline explaining swordsmanship breathing styles.",
      fullBody:
          "Breathing Styles are specialized swordsmanship forms practiced and taught by the Demon Slayer Corps. Cyber-Flame combines traditional energy-amplified katana strikes with high-frequency thermal vibrations, allowing slayers to slice through heavy armor.",
    ),
    Fandom(
      id: 3,
      title: "Interstellar Odyssey: Dark Matter Gates",
      category: "scifi",
      depth: "intermediate",
      badge: "SCI-FI ARCHIVE",
      img: "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?auto=format&fit=crop&w=500&q=80",
      summary: "How warp propulsion gates function across outer rim solar systems.",
      fullBody:
          "Dark Matter Gates utilize quantum entanglement to collapse local spacetime vectors. First engineered by the Orion Syndicate, these structures allow instantaneous transit across sub-light distances.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final q = widget.searchQuery.toLowerCase();
    final filteredList = loreList.where((item) {
      final matchesCategory = _selectedCategory == 'all' || item.category == _selectedCategory;
      final matchesSearch = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.summary.toLowerCase().contains(q);
      final matchesDepth = _activeDepth == 'all' || item.depth == _activeDepth;
      return matchesCategory && matchesSearch && matchesDepth;
    }).toList();

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

          // ── Category chips (loaded from Firestore categories collection) ──
          FutureBuilder<List<AppCategory>>(
            future: _categoriesFuture,
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

          // ── Lore cards ────────────────────────────────────────────
          filteredList.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No lore archives found.',
                        style: AppTheme.inter(size: 12, color: Colors.grey)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredList.length,
                  itemBuilder: (context, idx) => _loreCard(context, filteredList[idx]),
                ),
        ],
      ),
    );
  }

  // ── Category chip ──────────────────────────────────────────────────
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

  // ── Depth segmented control segment ───────────────────────────────
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

  // ── Depth overlay pill ─────────────────────────────────────────────
  Widget _depthPill(String depth) {
    final Color bg;
    final Color fg;
    final String label;
    switch (depth) {
      case 'beginner':
        bg = const Color(0xFF166534);
        fg = const Color(0xFF4ADE80);
        label = 'BEGINNER';
      case 'deep':
        bg = AppTheme.accent.withValues(alpha: 0.25);
        fg = AppTheme.accent;
        label = 'DEEP DIVE';
      default:
        bg = AppTheme.orange.withValues(alpha: 0.2);
        fg = AppTheme.orange;
        label = depth.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.orbitron(color: fg, fontSize: 8, fontWeight: FontWeight.w700)),
    );
  }

  // ── Full lore card ─────────────────────────────────────────────────
  Widget _loreCard(BuildContext context, Fandom item) {
    final isBookmarked = _bookmarkedIds.contains(item.id);
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
          // Image with overlaid pills and bookmark button
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  item.img,
                  height: 144,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Top-left: badge pill + depth pill
              Positioned(
                top: 8,
                left: 8,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.badge,
                        style: GoogleFonts.orbitron(
                            color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _depthPill(item.depth),
                  ],
                ),
              ),
              // Top-right: bookmark toggle
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() {
                    isBookmarked ? _bookmarkedIds.remove(item.id) : _bookmarkedIds.add(item.id);
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isBookmarked ? AppTheme.cyan : Colors.black.withValues(alpha: 0.55),
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
          // Text area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.orbitron(size: 13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  item.summary,
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
                          item.category.toUpperCase(),
                          style: AppTheme.inter(size: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FandomDetailScreen(fandom: item)),
                      ),
                      child: Row(
                        children: [
                          Text('Read Archive',
                              style: AppTheme.inter(
                                  size: 12, color: AppTheme.cyan, weight: FontWeight.w600)),
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
