import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../models/merchandise.dart';
import '../../models/post.dart';
import '../../services/merchandise_service.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import 'content_moderation_screen.dart';

/// Admin view of everything tagged with one category: all Posts (active and
/// inactive) and all Merchandise. Rows are the same ones used in the Content
/// tab, so edit/delete behave identically.
class CategoryContentScreen extends StatefulWidget {
  final AppCategory category;
  const CategoryContentScreen({super.key, required this.category});

  @override
  State<CategoryContentScreen> createState() => _CategoryContentScreenState();
}

class _CategoryContentScreenState extends State<CategoryContentScreen> {
  // Created once so rebuilds don't resubscribe and flash the loading state.
  // Posts use the same filter as the fan Category Detail screen, applied to
  // watchPosts() so inactive posts are included (matches the row badge).
  late final Stream<List<Post>> _postsStream = PostService.instance
      .watchPosts()
      .map((posts) =>
          posts.where((p) => p.category == widget.category.key).toList());
  late final Stream<List<Merchandise>> _merchStream = MerchandiseService
      .instance
      .watchMerchandiseByCategory(widget.category.key);

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
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
        title: Text('${cat.name} — Content', style: AppTheme.orbitron(size: 13)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: AppTheme.orange.withValues(alpha: 0.3)),
        ),
      ),
      body: StreamBuilder<List<Post>>(
        stream: _postsStream,
        builder: (context, postSnap) => StreamBuilder<List<Merchandise>>(
          stream: _merchStream,
          builder: (context, merchSnap) {
            final bothEmpty = postSnap.hasData &&
                merchSnap.hasData &&
                postSnap.data!.isEmpty &&
                merchSnap.data!.isEmpty;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(cat),
                const SizedBox(height: 20),
                if (bothEmpty)
                  _nothingTagged(cat)
                else ...[
                  _sectionTitle('POSTS', Icons.article_outlined, AppTheme.cyan,
                      postSnap.data?.length),
                  const SizedBox(height: 10),
                  ..._section<Post>(
                    snap: postSnap,
                    color: AppTheme.cyan,
                    errorText: 'Could not load posts',
                    emptyText: 'No posts in this category yet',
                    row: (p) => adminPostRow(context, p),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('PRODUCTS', Icons.shopping_bag_outlined,
                      AppTheme.orange, merchSnap.data?.length),
                  const SizedBox(height: 10),
                  ..._section<Merchandise>(
                    snap: merchSnap,
                    color: AppTheme.orange,
                    errorText: 'Could not load products',
                    emptyText: 'No products in this category yet',
                    row: (m) => adminMerchRow(context, m),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _section<T>({
    required AsyncSnapshot<List<T>> snap,
    required Color color,
    required String errorText,
    required String emptyText,
    required Widget Function(T) row,
  }) {
    if (snap.hasError) {
      debugPrint('$errorText: ${snap.error}');
      return [
        _stateBox(Icons.wifi_off, '$errorText. Check your connection and try again.',
            Colors.redAccent),
      ];
    }
    if (!snap.hasData) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
        ),
      ];
    }
    final items = snap.data!;
    if (items.isEmpty) {
      return [_stateBox(Icons.inbox_outlined, emptyText, Colors.grey)];
    }
    return [
      for (final item in items)
        Padding(padding: const EdgeInsets.only(bottom: 8), child: row(item)),
    ];
  }

  Widget _header(AppCategory cat) => Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                ? Image.network(
                    cat.imageUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, st) => _imageFallback(),
                  )
                : _imageFallback(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name,
                    style: AppTheme.orbitron(size: 15, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('key: ${cat.key}  •  ${cat.isActive ? 'Active' : 'Inactive'}',
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      );

  Widget _imageFallback() => Container(
        width: 72,
        height: 72,
        color: AppTheme.orange.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: const Icon(Icons.category_outlined,
            color: AppTheme.orange, size: 30),
      );

  Widget _sectionTitle(String title, IconData icon, Color color, int? count) =>
      Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(title, style: AppTheme.orbitron(size: 11, color: color)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$count',
                  style: AppTheme.inter(
                      size: 10, color: color, weight: FontWeight.w700)),
            ),
          ],
        ],
      );

  Widget _stateBox(IconData icon, String text, Color color) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text, style: AppTheme.inter(size: 12, color: color))),
          ],
        ),
      );

  Widget _nothingTagged(AppCategory cat) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.orange.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Icon(Icons.folder_off_outlined,
                color: AppTheme.orange, size: 44),
            const SizedBox(height: 14),
            Text('Nothing tagged "${cat.name}" yet',
                textAlign: TextAlign.center,
                style: AppTheme.orbitron(size: 13, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '0 posts  •  0 products\n'
              'Assign this category from the post or merchandise form to see items here.',
              textAlign: TextAlign.center,
              style: AppTheme.inter(size: 12, color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      );
}
