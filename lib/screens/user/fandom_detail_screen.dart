import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/fandom.dart';

class FandomDetailScreen extends StatelessWidget {
  final Fandom fandom;

  const FandomDetailScreen({super.key, required this.fandom});

  @override
  Widget build(BuildContext context) {
    final color = Fandom.colorFor(fandom.category);

    return Scaffold(
      appBar: AppBar(title: Text(fandom.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Fandom.iconFor(fandom.category), color: color, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fandom.name,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(fandom.category, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (fandom.description.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(fandom.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), height: 1.5)),
          ],
          const SizedBox(height: 28),
          const Text('Latest Posts', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('fandom_category', isEqualTo: fandom.category)
                .orderBy('timestamp', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Could not load posts.', style: TextStyle(color: Colors.white54)),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No posts yet for this fandom.', style: TextStyle(color: Colors.white54)),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final title = (data['title'] as String?) ?? 'Untitled';
                  final body = (data['content_body'] as String?) ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161F),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
