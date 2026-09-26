import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lore_card.dart';

/// Generic "list of Posts" screen reused for content-type quick filters
/// and the Explore Latest "See All" destination.
class PostListScreen extends StatelessWidget {
  final String title;
  final Stream<List<Post>> stream;
  final String emptyMessage;

  const PostListScreen({
    super.key,
    required this.title,
    required this.stream,
    this.emptyMessage = 'Nothing here yet.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTheme.orbitron(size: 13)),
      ),
      body: StreamBuilder<List<Post>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.grey, size: 28),
                  const SizedBox(height: 8),
                  Text('Could not load posts',
                      style: AppTheme.inter(size: 12, color: Colors.grey)),
                ],
              ),
            );
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_outlined, color: Colors.grey, size: 36),
                  const SizedBox(height: 10),
                  Text(emptyMessage,
                      style: AppTheme.inter(size: 12, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, i) => LoreCard(post: posts[i]),
          );
        },
      ),
    );
  }
}
