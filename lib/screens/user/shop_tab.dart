import 'package:flutter/material.dart';
import '../../models/merchandise.dart';
import '../../services/merchandise_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_header.dart';

/// Merchandise grid, moved here from the old ExploreTab (which was
/// repurposed into the Explore/Lore landing page).
class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.shopping_bag,
            iconColor: AppTheme.orange,
            title: 'OFFICIAL MERCHANDISE',
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Merchandise>>(
            stream: MerchandiseService.instance.watchMerchandise(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange),
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
                        Text('Could not load merchandise',
                            style: AppTheme.inter(size: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              final merch = snapshot.data ?? [];
              if (merch.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 36),
                        const SizedBox(height: 10),
                        Text('No merchandise available',
                            style: AppTheme.orbitron(
                                size: 12, color: Colors.grey, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Official merchandise will appear here when listed.',
                            style: AppTheme.inter(size: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: merch.length,
                itemBuilder: (context, idx) => _merchCard(context, merch[idx]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _merchCard(BuildContext context, Merchandise item) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => Container(
                        color: AppTheme.bg,
                        alignment: Alignment.center,
                        child: const Icon(Icons.shopping_bag_outlined,
                            color: Colors.white24, size: 36),
                      ),
                    )
                  : Container(
                      color: AppTheme.bg,
                      alignment: Alignment.center,
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: Colors.white24, size: 36),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(size: 12, weight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: AppTheme.orbitron(size: 13, color: AppTheme.orange, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${item.name} added to cart!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      '+ Cart',
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
