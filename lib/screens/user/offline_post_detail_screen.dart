import 'package:flutter/material.dart';
import '../../models/offline_saved_post.dart';
import '../../services/offline_service.dart';
import '../../theme/app_theme.dart';

/// Renders entirely from local storage — no network calls — so it works
/// correctly with no connection at all.
class OfflinePostDetailScreen extends StatelessWidget {
  final OfflineSavedPost post;
  const OfflinePostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.card,
            flexibleSpace: FlexibleSpaceBar(
              background: post.imageBytes != null
                  ? Image.memory(post.imageBytes!, fit: BoxFit.cover)
                  : Container(
                      color: AppTheme.card,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: Colors.white24, size: 40),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Remove download',
                onPressed: () async {
                  await OfflineService.instance.removeOffline(post.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppTheme.cyan, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          post.category.isEmpty ? 'LORE ARCHIVE' : post.category.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.offline_pin, color: AppTheme.accent, size: 14),
                      const SizedBox(width: 3),
                      Text('SAVED OFFLINE',
                          style: AppTheme.inter(size: 10, color: AppTheme.accent)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    post.content,
                    style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
