import 'dart:async';

import 'package:flutter/material.dart';
import '../../../models/post.dart';
import '../../../models/tag.dart';
import '../../../services/post_service.dart';
import '../../../services/tag_service.dart';
import '../../../theme/app_theme.dart';

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  StreamSubscription<List<Tag>>? _tagSub;
  StreamSubscription<List<Post>>? _postSub;
  List<Tag>? _tags;
  Map<String, int> _counts = const {};
  bool _postsLoaded = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _tagSub = TagService.instance.watchAll().listen(
          (tags) => setState(() => _tags = tags),
          onError: (Object e) => setState(() => _error = e),
        );
    _postSub = PostService.instance.watchPosts().listen(
          (posts) => setState(() {
            _counts = TagService.countsFrom(posts);
            _postsLoaded = true;
          }),
          onError: (Object e) => setState(() => _error = e),
        );
  }

  @override
  void dispose() {
    _tagSub?.cancel();
    _postSub?.cancel();
    super.dispose();
  }

  int _count(Tag t) => _counts[t.id] ?? 0;

  @override
  Widget build(BuildContext context) {
    final tags = _tags;
    Widget body;
    if (_error != null) {
      debugPrint('Tags load error: $_error');
      body = Center(
          child: Text('Could not load tags. Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTheme.inter(color: Colors.red)));
    } else if (tags == null || !_postsLoaded) {
      body = const Center(
          child: CircularProgressIndicator(color: AppTheme.orange));
    } else if (tags.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sell_outlined, color: Colors.grey, size: 36),
            const SizedBox(height: 12),
            Text('No tags yet',
                style: AppTheme.inter(size: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Tags are created when you add them to a post',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
          ],
        ),
      );
    } else {
      final sorted = List<Tag>.from(tags)
        ..sort((a, b) {
          final byCount = _count(b).compareTo(_count(a));
          return byCount != 0 ? byCount : a.id.compareTo(b.id);
        });
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: sorted.length,
        itemBuilder: (context, i) => _row(sorted[i]),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('Tags', style: AppTheme.orbitron(size: 13))),
              Text('Sorted by posts',
                  style: AppTheme.inter(size: 11, color: Colors.grey)),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _row(Tag t) {
    final count = _count(t);
    return Container(
      key: ValueKey(t.id),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: t.isPinned
                ? AppTheme.orange.withValues(alpha: 0.6)
                : AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.sell_outlined, color: AppTheme.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${t.id}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(
                        size: 13, color: Colors.white, weight: FontWeight.w600)),
                Text(
                    '${t.name != t.id ? '${t.name} · ' : ''}$count post${count == 1 ? '' : 's'}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: t.isPinned ? 'Unpin' : 'Pin',
            icon: Icon(t.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: t.isPinned ? AppTheme.orange : Colors.grey, size: 18),
            onPressed: () => _run(
                () => TagService.instance.setPinned(t.id, !t.isPinned),
                t.isPinned ? '#${t.id} unpinned' : '#${t.id} pinned'),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 18),
            onPressed: () => _delete(t),
          ),
        ],
      ),
    );
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      debugPrint('Tag action failed: $e');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Could not save. Check your connection and try again.')));
    }
  }

  Future<void> _delete(Tag t) async {
    final count = _count(t);
    if (count > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Can\'t delete #${t.id}',
              style: AppTheme.orbitron(size: 12, color: Colors.white)),
          content: Text(
              'It is used by $count post${count == 1 ? '' : 's'}. Remove it from those posts first.',
              style: AppTheme.inter(size: 12, color: Colors.grey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK',
                  style: AppTheme.orbitron(size: 9, color: AppTheme.orange)),
            ),
          ],
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete #${t.id}?',
            style: AppTheme.orbitron(size: 12, color: Colors.white)),
        content: Text('No posts use this tag. This cannot be undone.',
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
                style: AppTheme.orbitron(size: 9, color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => TagService.instance.delete(t.id), '#${t.id} deleted');
    }
  }
}
