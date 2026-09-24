import 'package:flutter/material.dart';
import '../../models/fandom.dart';
import '../../theme/app_theme.dart';

class FandomDetailScreen extends StatelessWidget {
  final Fandom fandom;

  const FandomDetailScreen({super.key, required this.fandom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.card,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(fandom.img, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.cyan, borderRadius: BorderRadius.circular(6)),
                    child: Text(fandom.badge, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text(fandom.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Text(fandom.fullBody, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}