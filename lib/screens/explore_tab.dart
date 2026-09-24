import 'package:flutter/material.dart';
import '../models/fandom.dart';
import '../services/fandom_service.dart';
import 'user/fandom_detail_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  static const _categories = ['All', 'Anime', 'Gaming', 'Comics', 'Movies & TV', 'Music', 'Sci-Fi'];

  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore Fandoms',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Search and filter by fandom category',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search fandoms...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCategory = category),
                        selectedColor: const Color(0xFF8B5CF6),
                        backgroundColor: const Color(0xFF16161F),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: isSelected ? const Color(0xFF8B5CF6) : Colors.white24),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Fandom>>(
              stream: FandomService.streamFandoms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const _MessageState(
                    icon: Icons.error_outline,
                    message: 'Could not load fandoms. Check your connection.',
                  );
                }

                final allFandoms = snapshot.data ?? [];
                final filtered = allFandoms.where((fandom) {
                  final matchesCategory = _selectedCategory == 'All' || fandom.category == _selectedCategory;
                  final matchesSearch = _searchQuery.isEmpty || fandom.name.toLowerCase().contains(_searchQuery);
                  return matchesCategory && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return _MessageState(
                    icon: Icons.search_off,
                    message: allFandoms.isEmpty
                        ? 'No fandoms have been added yet.'
                        : 'No fandoms match your search.',
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final fandom = filtered[index];
                    final color = Fandom.colorFor(fandom.category);
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FandomDetailScreen(fandom: fandom)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Fandom.iconFor(fandom.category), color: color, size: 30),
                            const Spacer(),
                            Text(
                              fandom.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(fandom.category, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MessageState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
