import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/offline_saved_post.dart';
import '../../services/offline_service.dart';
import '../../theme/app_theme.dart';
import 'offline_post_detail_screen.dart';

/// Reads local storage only — must work correctly in airplane mode.
class OfflineDownloadsScreen extends StatelessWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Offline Downloads', style: AppTheme.orbitron(size: 13)),
      ),
      body: FutureBuilder<ValueListenable<Box>>(
        future: OfflineService.instance.listenable(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan));
          }
          return ValueListenableBuilder<Box>(
            valueListenable: snap.data!,
            builder: (context, box, _) {
              final posts = box.values
                  .map((v) =>
                      OfflineSavedPost.fromMap(Map<String, dynamic>.from(v as Map)))
                  .toList()
                ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

              if (posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.download_for_offline_outlined,
                          color: Colors.grey, size: 36),
                      const SizedBox(height: 10),
                      Text('No downloads yet',
                          style: AppTheme.orbitron(
                              size: 12, color: Colors.grey, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Save a post for offline from its detail page. Downloads are full copies kept on this device and work without internet.',
                          style: AppTheme.inter(size: 11, color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, i) => _downloadRow(context, posts[i]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _downloadRow(BuildContext context, OfflineSavedPost post) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OfflinePostDetailScreen(post: post)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: post.imageBytes != null
                    ? Image.memory(post.imageBytes!, width: 56, height: 56, fit: BoxFit.cover)
                    : Container(
                        width: 56,
                        height: 56,
                        color: AppTheme.bg,
                        alignment: Alignment.center,
                        child: const Icon(Icons.article_outlined,
                            color: Colors.white24, size: 22),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(
                            size: 13, color: Colors.white, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(post.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.offline_pin, color: AppTheme.accent, size: 18),
            ],
          ),
        ),
      );
}
