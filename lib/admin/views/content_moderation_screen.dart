import 'package:flutter/material.dart';
import '../../models/event_item.dart';
import '../../models/merchandise.dart';
import '../../models/post.dart';
import '../../services/event_service.dart';
import '../../services/merchandise_service.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import 'event_form_screen.dart';
import 'merchandise_form_screen.dart';
import 'post_form_screen.dart';

class ContentModerationScreen extends StatelessWidget {
  const ContentModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: AppTheme.card,
            child: TabBar(
              labelStyle: AppTheme.orbitron(size: 9, weight: FontWeight.w700),
              unselectedLabelStyle:
                  AppTheme.orbitron(size: 9, weight: FontWeight.w500),
              indicatorColor: AppTheme.cyan,
              labelColor: AppTheme.cyan,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'LORE'),
                Tab(text: 'MERCH'),
                Tab(text: 'EVENTS'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _PostsTab(),
                _MerchandiseTab(),
                _EventsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Posts / Lore tab ──────────────────────────────────────────────────────────

class _PostsTab extends StatelessWidget {
  const _PostsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: PostService.instance.watchPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.cyan));
        }
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }
        final posts = snapshot.data ?? [];
        return Column(
          children: [
            _sectionHeader(
              context,
              'Lore Posts',
              AppTheme.cyan,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PostFormScreen()),
              ),
            ),
            Expanded(
              child: posts.isEmpty
                  ? _emptyView('No posts yet', 'Tap ADD to write lore content')
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: posts.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          _postRow(context, posts[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _postRow(BuildContext context, Post post) {
    return _itemCard(
      context,
      icon: Icons.article_outlined,
      iconColor: AppTheme.cyan,
      title: post.title,
      subtitle:
          '${post.category.isEmpty ? 'No category' : post.category}  •  ${_fmtDate(post.createdAt)}',
      onEdit: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PostFormScreen(existing: post)),
      ),
      onDelete: () => _confirmDelete(
        context,
        'Delete "${post.title}"?',
        () => PostService.instance.deletePost(post.id),
      ),
    );
  }
}

// ── Merchandise tab ───────────────────────────────────────────────────────────

class _MerchandiseTab extends StatelessWidget {
  const _MerchandiseTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Merchandise>>(
      stream: MerchandiseService.instance.watchMerchandise(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.orange));
        }
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }
        final items = snapshot.data ?? [];
        return Column(
          children: [
            _sectionHeader(
              context,
              'Merchandise',
              AppTheme.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MerchandiseFormScreen()),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? _emptyView(
                      'No products yet', 'Tap ADD to list merchandise')
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          _merchRow(context, items[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _merchRow(BuildContext context, Merchandise item) {
    return _itemCard(
      context,
      icon: Icons.shopping_bag_outlined,
      iconColor: AppTheme.orange,
      title: item.name,
      subtitle:
          '\$${item.price.toStringAsFixed(2)}  •  ${item.category.isEmpty ? 'No category' : item.category}',
      onEdit: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MerchandiseFormScreen(existing: item)),
      ),
      onDelete: () => _confirmDelete(
        context,
        'Delete "${item.name}"?',
        () => MerchandiseService.instance.deleteMerchandise(item.id),
      ),
    );
  }
}

// ── Events tab ────────────────────────────────────────────────────────────────

class _EventsTab extends StatelessWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventItem>>(
      stream: EventService.instance.watchEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.pink));
        }
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }
        final events = snapshot.data ?? [];
        return Column(
          children: [
            _sectionHeader(
              context,
              'Events',
              AppTheme.pink,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EventFormScreen()),
              ),
            ),
            Expanded(
              child: events.isEmpty
                  ? _emptyView(
                      'No events yet', 'Tap ADD to list a convention or event')
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: events.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          _eventRow(context, events[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _eventRow(BuildContext context, EventItem event) {
    return _itemCard(
      context,
      icon: Icons.event,
      iconColor: AppTheme.pink,
      title: event.title,
      subtitle:
          '${event.city}  •  ${_fmtDate(event.date)}  •  ${event.venue}',
      onEdit: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EventFormScreen(existing: event)),
      ),
      onDelete: () => _confirmDelete(
        context,
        'Delete "${event.title}"?',
        () => EventService.instance.deleteEvent(event.id),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _sectionHeader(
  BuildContext context,
  String title,
  Color accentColor,
  VoidCallback onAdd,
) =>
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  AppTheme.orbitron(size: 12, color: accentColor)),
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 15),
            label: Text('ADD', style: AppTheme.orbitron(size: 9)),
          ),
        ],
      ),
    );

Widget _itemCard(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(
                        size: 13, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(
                        size: 10, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.cyan, size: 17),
            onPressed: onEdit,
            tooltip: 'Edit',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 17),
            onPressed: onDelete,
            tooltip: 'Delete',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );

Widget _errorView(String message) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error: $message',
            style: AppTheme.inter(size: 12, color: Colors.redAccent),
            textAlign: TextAlign.center),
      ),
    );

Widget _emptyView(String title, String subtitle) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, color: Colors.grey, size: 36),
          const SizedBox(height: 12),
          Text(title, style: AppTheme.inter(size: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: AppTheme.inter(size: 11, color: Colors.grey)),
        ],
      ),
    );

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<void> _confirmDelete(
  BuildContext context,
  String message,
  Future<void> Function() onConfirm,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.card,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(message,
          style: AppTheme.orbitron(size: 12, color: Colors.white)),
      content: Text('This cannot be undone.',
          style: AppTheme.inter(size: 12, color: Colors.grey)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child:
              Text('CANCEL', style: AppTheme.orbitron(size: 9, color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('DELETE',
              style: AppTheme.orbitron(size: 9, color: Colors.redAccent)),
        ),
      ],
    ),
  );
  if (confirm == true) await onConfirm();
}
