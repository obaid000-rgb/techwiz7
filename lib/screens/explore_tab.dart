import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_header.dart';

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> events = [
      {
        'title': 'Tokyo Cyber-Anime Expo 2026',
        'date': 'OCT 14-16, 2026 • Tokyo, JP',
        'img': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=400&q=80',
      },
      {
        'title': 'Cyberpunk Netrunner Arena',
        'date': 'NOV 02-04, 2026 • Online',
        'img': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=400&q=80',
      },
    ];

    final List<Map<String, String>> merch = [
      {
        'title': 'Neon Katana Prop Replica',
        'price': '\$120.00',
        'img': 'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=300&q=80',
      },
      {
        'title': 'Arasaka Vault Jacket (Limited)',
        'price': '\$85.00',
        'img': 'https://images.unsplash.com/photo-1551028719-00167b16eac5?auto=format&fit=crop&w=300&q=80',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conventions Header
          const SectionHeader(
            icon: Icons.confirmation_number,
            iconColor: AppTheme.pink,
            title: 'FANDOM CONVENTIONS',
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, idx) {
              final ev = events[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(ev['img']!, width: 75, height: 75, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ev['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(ev['date']!, style: const TextStyle(fontSize: 10, color: AppTheme.cyan)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pass reserved! Check your email.')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.pink.withOpacity(0.2),
                              side: const BorderSide(color: AppTheme.pink),
                              minimumSize: const Size(90, 28),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Get Pass', style: TextStyle(fontSize: 11, color: AppTheme.pink, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Official Merch Header
          const SectionHeader(
            icon: Icons.shopping_bag,
            iconColor: AppTheme.cyan,
            title: 'OFFICIAL MERCHANDISE',
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: merch.length,
            itemBuilder: (context, idx) {
              final item = merch[idx];
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
                        child: Image.network(item['img']!, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['price']!, style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold, fontSize: 12)),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.white),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${item['title']} added to cart!')),
                                  );
                                },
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}