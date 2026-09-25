import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lore_card.dart';

class CategoryDetailScreen extends StatelessWidget {
  final AppCategory category;
  const CategoryDetailScreen({super.key, required this.category});

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
        title: Text(category.name, style: AppTheme.orbitron(size: 13)),
      ),
      body: StreamBuilder<List<Post>>(
        stream: PostService.instance.watchActivePosts(),
        builder: (context, snapshot) {
          final posts = (snapshot.data ?? [])
              .where((p) => p.category == category.key)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(),
              const SizedBox(height: 20),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.cyan),
                  ),
                )
              else if (posts.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          color: Colors.grey, size: 36),
                      const SizedBox(height: 10),
                      Text('No posts in this category yet',
                          style:
                              AppTheme.inter(size: 12, color: Colors.grey)),
                    ],
                  ),
                )
              else
                ...posts.map((p) => LoreCard(post: p)),
            ],
          );
        },
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: category.imageUrl != null && category.imageUrl!.isNotEmpty
              ? Image.network(
                  category.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, st) => _headerFallback(),
                )
              : _headerFallback(),
        ),
        const SizedBox(height: 12),
        Text(category.name, style: AppTheme.orbitron(size: 16)),
        if (category.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(category.description,
              style: AppTheme.inter(size: 12, color: Colors.grey, height: 1.4)),
        ],
      ],
    );
  }

  Widget _headerFallback() => Container(
        height: 140,
        width: double.infinity,
        color: AppTheme.card,
        alignment: Alignment.center,
        child: const Icon(Icons.category_outlined,
            color: Colors.white24, size: 40),
      );
}
