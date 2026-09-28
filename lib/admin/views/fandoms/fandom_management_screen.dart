import 'dart:async';

import 'package:flutter/material.dart';
import '../../../models/app_category.dart';
import '../../../models/fandom.dart';
import '../../../models/post.dart';
import '../../../services/auth_service.dart';
import '../../../services/category_service.dart';
import '../../../services/fandom_service.dart';
import '../../../services/post_service.dart';
import '../../../theme/app_theme.dart';
import '../../controllers/fandoms/fandom_controller.dart';
import '../content/content_moderation_screen.dart';
import '../content/post_form_screen.dart';
import 'fandom_form_screen.dart';

class FandomManagementScreen extends StatefulWidget {
  const FandomManagementScreen({super.key});

  @override
  State<FandomManagementScreen> createState() => _FandomManagementScreenState();
}

class _FandomManagementScreenState extends State<FandomManagementScreen> {
  final _controller = const FandomController();
  final _searchCtr = TextEditingController();
  StreamSubscription<List<Fandom>>? _fandomSub;
  StreamSubscription<List<AppCategory>>? _categorySub;
  StreamSubscription<List<Post>>? _postSub;
  Map<String, int> _postCounts = {};
  List<Fandom>? _fandoms;
  List<AppCategory> _categories = [];
  Object? _loadError;
  String _query = '';
  String? _categoryFilter;
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _searchCtr.addListener(() => setState(() => _query = _searchCtr.text));
    _fandomSub = FandomService.instance.watchAll().listen(
      (list) => setState(() {
        _fandoms = list;
        _loadError = null;
      }),
      onError: (Object e) => setState(() => _loadError = e),
    );
    _categorySub = CategoryService.instance.watchCategories().listen(
      (cats) => setState(() => _categories = cats),
    );
    _postSub = PostService.instance.watchPosts().listen((posts) {
      final counts = <String, int>{};
      for (final p in posts) {
        if (p.hasFandom) counts[p.fandomId] = (counts[p.fandomId] ?? 0) + 1;
      }
      setState(() => _postCounts = counts);
    });
  }

  @override
  void dispose() {
    _fandomSub?.cancel();
    _categorySub?.cancel();
    _postSub?.cancel();
    _searchCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fandoms = _fandoms;
    Widget body;
    if (_loadError != null && fandoms == null) {
      debugPrint('Fandoms load error: $_loadError');
      body = Center(
        child: Text(
          'Could not load fandoms. Check your connection and try again.',
          textAlign: TextAlign.center,
          style: AppTheme.inter(color: Colors.red),
        ),
      );
    } else if (fandoms == null) {
      body = const Center(
        child: CircularProgressIndicator(color: AppTheme.orange),
      );
    } else if (fandoms.isEmpty) {
      body = _message(
        Icons.hub_outlined,
        'No fandoms yet',
        'Tap ADD, or SEED to add the demo fandoms',
      );
    } else {
      final groups = _controller.group(
        fandoms,
        _categories,
        categoryId: _categoryFilter,
        query: _query,
      );
      body = groups.isEmpty
          ? _message(
              Icons.search_off,
              'No fandoms match',
              'Try another search or category',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                for (final g in groups) ...[
                  _groupHeader(g),
                  for (final f in g.fandoms) _row(f),
                ],
              ],
            );
    }

    return Column(
      children: [
        _header(),
        _filters(),
        Expanded(child: body),
      ],
    );
  }

  Widget _header() {
    final isAdmin = AuthService.instance.currentUser?.isAdmin ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(child: Text('Fandoms', style: AppTheme.orbitron(size: 13))),
          if (isAdmin) ...[
            OutlinedButton.icon(
              onPressed: _seeding ? null : _seed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.orange,
                side: const BorderSide(color: AppTheme.orange),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _seeding
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.orange,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_outlined, size: 16),
              label: Text('SEED', style: AppTheme.orbitron(size: 9)),
            ),
            const SizedBox(width: 8),
          ],
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FandomFormScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: Text('ADD', style: AppTheme.orbitron(size: 9)),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    final cats = List<AppCategory>.from(_categories)
      ..sort((a, b) => a.order.compareTo(b.order));
    final filterValue = cats.any((c) => c.key == _categoryFilter)
        ? _categoryFilter
        : null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.border),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButton<String?>(
              value: filterValue,
              isExpanded: true,
              dropdownColor: AppTheme.card,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.expand_more, color: AppTheme.orange),
              style: AppTheme.inter(size: 13, color: Colors.white),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All categories'),
                ),
                for (final c in cats)
                  DropdownMenuItem<String?>(
                    value: c.key,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryFilter = v),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtr,
            style: AppTheme.inter(size: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search fandoms…',
              hintStyle: AppTheme.inter(size: 13, color: Colors.grey),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
                size: 18,
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 16,
                      ),
                      onPressed: () => _searchCtr.clear(),
                    ),
              filled: true,
              fillColor: AppTheme.card,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: const BorderSide(color: AppTheme.orange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(IconData icon, String title, String subtitle) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.grey, size: 36),
        const SizedBox(height: 12),
        Text(title, style: AppTheme.inter(size: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTheme.inter(size: 11, color: Colors.grey)),
      ],
    ),
  );

  Widget _groupHeader(FandomGroup g) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
    child: Row(
      children: [
        const Icon(Icons.category_outlined, color: AppTheme.orange, size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            g.categoryName.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: AppTheme.orbitron(size: 10, color: AppTheme.orange),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${g.fandoms.length}',
          style: AppTheme.inter(size: 10, color: Colors.grey),
        ),
      ],
    ),
  );

  Widget _row(Fandom f) => Container(
    key: ValueKey(f.id),
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: f.isActive
            ? AppTheme.border
            : Colors.redAccent.withValues(alpha: 0.35),
      ),
    ),
    child: Row(
      children: [
        Opacity(opacity: f.isActive ? 1 : 0.5, child: _logo(f)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      f.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.orbitron(
                        size: 11,
                        weight: FontWeight.w700,
                        color: f.isActive ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  if (f.isTrending) ...[
                    const SizedBox(width: 6),
                    const Tooltip(
                      message: 'Pinned to Trending',
                      child: Icon(
                        Icons.local_fire_department,
                        color: AppTheme.pink,
                        size: 14,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                f.categoryName.isEmpty ? 'No category' : f.categoryName,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.inter(size: 10, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _postCountBadge(_postCounts[f.id] ?? 0),
                  if (!f.isActive) _inactiveBadge(),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.article_outlined,
            color: AppTheme.orange,
            size: 18,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _FandomPostsScreen(fandom: f)),
          ),
          tooltip: 'View posts',
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.edit_outlined, color: AppTheme.cyan, size: 18),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FandomFormScreen(existing: f)),
          ),
          tooltip: 'Edit',
        ),
        if (f.isActive)
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 18,
            ),
            onPressed: () => _confirmSoftDelete(f),
            tooltip: 'Deactivate',
          )
        else
          TextButton(
            onPressed: () => _run(
              () => FandomService.instance.restore(f.id),
              '"${f.name}" restored',
            ),
            child: Text(
              'RESTORE',
              style: AppTheme.orbitron(size: 8, color: Colors.green),
            ),
          ),
      ],
    ),
  );

  Widget _postCountBadge(int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.cyan.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
    ),
    child: Text(
      '$count post${count == 1 ? '' : 's'}',
      style: AppTheme.inter(size: 9, color: AppTheme.cyan),
    ),
  );

  Widget _inactiveBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.redAccent.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.redAccent, width: 0.5),
    ),
    child: Text(
      'Inactive',
      style: AppTheme.inter(size: 9, color: Colors.redAccent),
    ),
  );

  Widget _logo(Fandom f, {double size = 44}) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        f.name.isEmpty ? '?' : f.name.characters.first.toUpperCase(),
        style: AppTheme.orbitron(size: 14, color: AppTheme.orange),
      ),
    );
    if (f.logoUrl.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        f.logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (ctx, e, st) => fallback,
      ),
    );
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      debugPrint('Fandom action failed: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not save. Check your connection and try again.'),
        ),
      );
    }
  }

  Future<void> _confirmSoftDelete(Fandom f) async {
    Map<String, int> counts;
    try {
      counts = await FandomService.instance.postCounts(f.id);
    } catch (e) {
      debugPrint('Post count failed: $e');
      final n = _postCounts[f.id] ?? 0;
      counts = {'total': n, 'active': n};
    }
    if (!mounted) return;
    final total = counts['total'] ?? 0;
    final active = counts['active'] ?? 0;
    final postsLine = total == 0
        ? 'It has no posts.'
        : 'It has $total post${total == 1 ? '' : 's'} ($active active). '
              'The posts are not changed.';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Deactivate "${f.name}"?',
          style: AppTheme.orbitron(size: 12, color: Colors.white),
        ),
        content: Text(
          '$postsLine\n\nIt will be marked Inactive. You can restore it at any time.',
          style: AppTheme.inter(size: 12, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: AppTheme.orbitron(size: 9, color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'DEACTIVATE',
              style: AppTheme.orbitron(size: 9, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _run(
        () => FandomService.instance.softDelete(f.id),
        '"${f.name}" deactivated',
      );
    }
  }

  Future<void> _seed() async {
    setState(() => _seeding = true);
    SeedResult? result;
    Object? error;
    try {
      result = await _controller.seedDemoFandoms();
    } catch (e) {
      debugPrint('Seed failed: $e');
      error = e;
    }
    if (!mounted) return;
    setState(() => _seeding = false);

    final lines = <Widget>[];
    void section(String title, List<String> names, Color color) {
      if (names.isEmpty) return;
      lines.add(
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            title,
            style: AppTheme.inter(
              size: 12,
              color: color,
              weight: FontWeight.w700,
            ),
          ),
        ),
      );
      lines.add(
        Text(
          names.join(', '),
          style: AppTheme.inter(size: 12, color: Colors.grey),
        ),
      );
    }

    if (result != null) {
      section(
        'Created (${result.created.length})',
        result.created,
        Colors.green,
      );
      section(
        'Already existed (${result.alreadyExisted.length})',
        result.alreadyExisted,
        AppTheme.cyan,
      );
      for (final e in result.skippedCategories.entries) {
        section('Skipped: no "${e.key}" category', e.value, Colors.redAccent);
      }
    } else {
      lines.add(
        Text(
          'Could not seed: check your connection and admin access.\n$error',
          style: AppTheme.inter(size: 12, color: Colors.redAccent),
        ),
      );
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Seed demo fandoms',
          style: AppTheme.orbitron(size: 12, color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: AppTheme.orbitron(size: 9, color: AppTheme.orange),
            ),
          ),
        ],
      ),
    );
  }
}

class _FandomPostsScreen extends StatefulWidget {
  final Fandom fandom;
  const _FandomPostsScreen({required this.fandom});

  @override
  State<_FandomPostsScreen> createState() => _FandomPostsScreenState();
}

class _FandomPostsScreenState extends State<_FandomPostsScreen> {
  late final Stream<List<Post>> _posts = PostService.instance
      .watchPostsByFandom(widget.fandom.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        title: Text(
          '${widget.fandom.name} · Posts',
          overflow: TextOverflow.ellipsis,
          style: AppTheme.orbitron(size: 13),
        ),
      ),
      body: StreamBuilder<List<Post>>(
        stream: _posts,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Fandom posts load error: ${snapshot.error}');
            return Center(
              child: Text(
                'Could not load posts. Check your connection and try again.',
                textAlign: TextAlign.center,
                style: AppTheme.inter(size: 12, color: Colors.redAccent),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.orange),
            );
          }
          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return _message(
              Icons.inbox_outlined,
              'No posts in this fandom yet',
              'Assign posts to it from Content → Lore',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: posts.length,
            separatorBuilder: (context, i) => const SizedBox(height: 8),
            itemBuilder: (context, i) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostFormScreen(existing: posts[i]),
                ),
              ),
              child: adminPostRow(context, posts[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _message(IconData icon, String title, String subtitle) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.grey, size: 36),
        const SizedBox(height: 12),
        Text(title, style: AppTheme.inter(size: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTheme.inter(size: 11, color: Colors.grey)),
      ],
    ),
  );
}
