import 'package:flutter/material.dart';
import '../../../models/app_category.dart';
import '../../../services/category_service.dart';
import '../../../theme/app_theme.dart';
import 'category_content_screen.dart';
import 'category_form_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _searchCtr = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtr.addListener(() {
      setState(() => _query = _searchCtr.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCategory>>(
      stream: CategoryService.instance.watchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.orange));
        }
        if (snapshot.hasError) {
          debugPrint('Categories load error: ${snapshot.error}');
          return Center(
              child: Text('Could not load categories. Check your connection and try again.',
                  style: AppTheme.inter(color: Colors.red)));
        }
        final cats = List<AppCategory>.from(snapshot.data ?? [])
          ..sort((a, b) => a.order.compareTo(b.order));
        final filtered = _query.isEmpty
            ? cats
            : cats
                .where((c) => c.name.toLowerCase().contains(_query))
                .toList();
        final isSearching = _query.isNotEmpty;

        return Column(
          children: [
            _header(context),
            _searchBox(),
            if (isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text('Clear search to drag-reorder',
                    style: AppTheme.inter(size: 10, color: Colors.grey)),
              ),
            Expanded(
              child: cats.isEmpty
                  ? _empty()
                  : filtered.isEmpty
                      ? _noResults()
                      : isSearching
                          ? _plainList(context, filtered)
                          : _reorderableList(context, cats),
            ),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Categories', style: AppTheme.orbitron(size: 13)),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CategoryFormScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text('ADD', style: AppTheme.orbitron(size: 9)),
            ),
          ],
        ),
      );

  Widget _searchBox() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: TextField(
          controller: _searchCtr,
          style: AppTheme.inter(size: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search categories…',
            hintStyle: AppTheme.inter(size: 13, color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                    onPressed: () => _searchCtr.clear(),
                  ),
            filled: true,
            fillColor: AppTheme.card,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.orange)),
          ),
        ),
      );

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, color: Colors.grey, size: 36),
            const SizedBox(height: 12),
            Text('No categories yet',
                style: AppTheme.inter(size: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Tap ADD to create the first one',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
          ],
        ),
      );

  Widget _noResults() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: Colors.grey, size: 36),
            const SizedBox(height: 12),
            Text('No categories match "${_searchCtr.text.trim()}"',
                style: AppTheme.inter(size: 12, color: Colors.grey)),
          ],
        ),
      );

  Widget _plainList(BuildContext context, List<AppCategory> cats) =>
      ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: cats.length,
        itemBuilder: (context, i) =>
            _catRow(context, cats[i], key: ValueKey(cats[i].id)),
      );

  Widget _reorderableList(BuildContext context, List<AppCategory> cats) =>
      ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: cats.length,
        // onReorder (not the newer onReorderItem) so older Flutter SDKs build.
        // ignore: deprecated_member_use
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex -= 1;
          final reordered = List<AppCategory>.from(cats);
          final moved = reordered.removeAt(oldIndex);
          reordered.insert(newIndex, moved);
          CategoryService.instance.reorderCategories(reordered);
        },
        itemBuilder: (context, i) =>
            _catRow(context, cats[i], key: ValueKey(cats[i].id)),
      );

  Widget _catRow(BuildContext context, AppCategory cat, {required Key key}) =>
      Container(
        key: key,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator, color: Colors.grey, size: 18),
            const SizedBox(width: 8),
            _thumb(cat),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(cat.name,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.orbitron(
                                size: 11, weight: FontWeight.w700)),
                      ),
                      if (cat.isFeaturedInCarousel) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Featured in Carousel',
                          child: Icon(Icons.view_carousel,
                              color: AppTheme.cyan, size: 13),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('key: ${cat.key}  •  order ${cat.order}',
                      style: AppTheme.inter(size: 10, color: Colors.grey)),
                  if (cat.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(cat.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTheme.inter(size: 10, color: Colors.white38)),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [_postCountBadge(cat), _statusBadge(cat)],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.folder_open_outlined,
                  color: AppTheme.orange, size: 18),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CategoryContentScreen(category: cat)),
              ),
              tooltip: 'View Content',
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined,
                  color: AppTheme.cyan, size: 18),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CategoryFormScreen(existing: cat)),
              ),
              tooltip: 'Edit',
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 18),
              onPressed: () => _confirmDelete(context, cat),
              tooltip: 'Delete',
            ),
          ],
        ),
      );

  Widget _postCountBadge(AppCategory cat) => StreamBuilder<int>(
        stream: CategoryService.instance.watchPostCount(cat.key),
        builder: (context, snap) {
          final count = snap.data ?? 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppTheme.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
            ),
            child: Text('$count post${count == 1 ? '' : 's'}',
                style: AppTheme.inter(size: 9, color: AppTheme.cyan)),
          );
        },
      );

  Widget _thumb(AppCategory cat, {double size = 44}) {
    if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          cat.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, e, st) => _thumbFallback(size),
        ),
      );
    }
    return _thumbFallback(size);
  }

  Widget _thumbFallback(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.category_outlined,
            color: AppTheme.orange, size: size * 0.45),
      );

  Widget _statusBadge(AppCategory cat) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: cat.isActive
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: cat.isActive ? Colors.green : Colors.redAccent,
            width: 0.5,
          ),
        ),
        child: Text(
          cat.isActive ? 'Active' : 'Inactive',
          style: AppTheme.inter(
            size: 9,
            color: cat.isActive ? Colors.green : Colors.redAccent,
          ),
        ),
      );

  Future<void> _confirmDelete(
      BuildContext context, AppCategory cat) async {
    final usage = await CategoryService.instance.checkUsage(cat.key);
    final total = (usage['posts'] ?? 0) +
        (usage['merchandise'] ?? 0) +
        (usage['fandoms'] ?? 0);
    if (!context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${cat.name}"?',
            style: AppTheme.orbitron(size: 12, color: Colors.white)),
        content: total > 0
            ? Text(
                'Still referenced by:\n'
                '  • ${usage['posts']} post(s)\n'
                '  • ${usage['merchandise']} merchandise item(s)\n'
                '  • ${usage['fandoms']} fandom(s)\n\n'
                'Deleting orphans those references. Continue?',
                style: AppTheme.inter(size: 12, color: Colors.grey))
            : Text('Remove this category? This cannot be undone.',
                style: AppTheme.inter(size: 12, color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL',
                style: AppTheme.orbitron(size: 9, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DELETE',
                style: AppTheme.orbitron(
                    size: 9, color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CategoryService.instance.deleteCategory(cat.id);
    }
  }
}
