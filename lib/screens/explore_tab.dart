import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> events = [
      {
        'title': 'Tokyo Cyber-Anime Expo 2026',
        'dateLabel': 'OCT 14',
        'date': 'OCT 14–16, 2026',
        'location': 'Tokyo, JP',
        'venue': 'Tokyo Big Sight Convention',
        'price': '\$45.00',
        'img': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=400&q=80',
      },
      {
        'title': 'Cyberpunk Netrunner Arena',
        'dateLabel': 'NOV 02',
        'date': 'NOV 02–04, 2026',
        'location': 'Online',
        'venue': 'Global Stream Platform',
        'price': 'Free',
        'img': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=400&q=80',
      },
    ];

    final List<Map<String, String>> merch = [
      {
        'title': 'Neon Katana Prop Replica',
        'price': '\$120.00',
        'rating': '4.9',
        'img': 'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=300&q=80',
      },
      {
        'title': 'Arasaka Vault Jacket (Limited)',
        'price': '\$85.00',
        'rating': '4.7',
        'img': 'https://images.unsplash.com/photo-1551028719-00167b16eac5?auto=format&fit=crop&w=300&q=80',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Conventions header ──────────────────────────────────
          SectionHeader(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail with dark gradient + date overlay
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(ev['img']!, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.75),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 5,
                          left: 0,
                          right: 0,
                          child: Text(
                            ev['dateLabel']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.orbitron(
                              color: AppTheme.cyan,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Event details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ev['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.orbitron(size: 12, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: AppTheme.cyan, size: 11),
                              const SizedBox(width: 3),
                              Text(ev['location']!,
                                  style: AppTheme.inter(size: 11, color: AppTheme.cyan)),
                            ],
                          ),
                          Text(ev['venue']!,
                              style: AppTheme.inter(size: 10, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ev['price']!,
                                style: AppTheme.orbitron(
                                    size: 12, color: AppTheme.cyan, weight: FontWeight.w700),
                              ),
                              // Pink ghost "Get Pass" button per spec
                              OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Pass reserved! Check your email.')),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppTheme.pink.withValues(alpha: 0.12),
                                  side: const BorderSide(color: AppTheme.pink),
                                  minimumSize: const Size(80, 26),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text('Get Pass',
                                    style: AppTheme.orbitron(
                                        size: 9, color: AppTheme.pink, weight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Merchandise header ──────────────────────────────────
          SectionHeader(
            icon: Icons.shopping_bag,
            iconColor: AppTheme.orange,
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
              childAspectRatio: 0.68,
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
                    // Image with rating badge overlay
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              item['img']!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Rating badge top-right
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${item['rating']} ⭐',
                                style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.inter(
                                size: 12, weight: FontWeight.w600, color: Colors.white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['price']!,
                            style: AppTheme.orbitron(
                                size: 13, color: AppTheme.orange, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          // Full-width solid orange cart button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${item['title']} added to cart!')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.orange,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                '+ Cart',
                                style: GoogleFonts.orbitron(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
