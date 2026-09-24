import 'package:flutter/material.dart';
import '../../models/fandom.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_header.dart';
import '../../widgets/trending_carousel.dart';
import 'fandom_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Fandom> loreList = [
    Fandom(
      id: 1,
      title: "Cyberpunk 2088: The Arasaka Vault Heist",
      category: "gaming",
      depth: "deep",
      badge: "EPISODE LORE",
      img: "https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=500&q=80",
      summary: "Complete breakdown of the legendary netrunner infiltration into orbital vault.",
      fullBody: "The Arasaka Vault Heist remains the most pivotal event in 2088 netrunning history. Executed by a rogue squad of Mercs, the operation breached three layers of security to retrieve the mythical Soulkiller 2.0 source code. This archive details step-by-step IC breaching and ICE protection protocols.",
    ),
    Fandom(
      id: 2,
      title: "Demon Slayer: Breath of Cyber-Flame",
      category: "anime",
      depth: "beginner",
      badge: "BEGINNER GUIDE",
      img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=500&q=80",
      summary: "An introductory timeline explaining swordsmanship breathing styles.",
      fullBody: "Breathing Styles are specialized swordsmanship forms practiced and taught by the Demon Slayer Corps. Cyber-Flame combines traditional energy-amplified katana strikes with high-frequency thermal vibrations, allowing slayers to slice through heavy armor.",
    ),
    Fandom(
      id: 3,
      title: "Interstellar Odyssey: Dark Matter Gates",
      category: "scifi",
      depth: "intermediate",
      badge: "SCI-FI ARCHIVE",
      img: "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?auto=format&fit=crop&w=500&q=80",
      summary: "How warp propulsion gates function across outer rim solar systems.",
      fullBody: "Dark Matter Gates utilize quantum entanglement to collapse local spacetime vectors. First engineered by the Orion Syndicate, these structures allow instantaneous transit across sub-light distances.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredList = loreList.where((item) {
      final matchesCategory = selectedCategory == 'all' || item.category == selectedCategory;
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.summary.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search Lore, Fandoms, Events...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
            ),
          ),
          const SizedBox(height: 20),

          // Trending Carousel Section
          const SectionHeader(
            icon: Icons.local_fire_department,
            iconColor: AppTheme.orange,
            title: 'TRENDING FANDOMS',
            trailingText: 'Live Feeds',
          ),
          const SizedBox(height: 12),
          const TrendingCarousel(),
          const SizedBox(height: 20),

          // Category Chips Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Realm', 'all'),
                _buildFilterChip('Anime & Manga', 'anime'),
                _buildFilterChip('Gaming & Esports', 'gaming'),
                _buildFilterChip('Sci-Fi & Movies', 'scifi'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lore Feed Section Header
          const SectionHeader(
            icon: Icons.menu_book,
            iconColor: AppTheme.cyan,
            title: 'LORE ARCHIVES & MEDIA',
          ),
          const SizedBox(height: 12),

          // Feed List
          filteredList.isEmpty
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text('No lore archives found matching criteria.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredList.length,
            itemBuilder: (context, idx) {
              final item = filteredList[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        item.img,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.cyan.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.cyan.withOpacity(0.4)),
                                ),
                                child: Text(
                                  item.badge,
                                  style: const TextStyle(color: AppTheme.cyan, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                item.category.toUpperCase(),
                                style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.summary,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FandomDetailScreen(fandom: item),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Read Archive', style: TextStyle(color: AppTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, size: 14, color: AppTheme.cyan),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}