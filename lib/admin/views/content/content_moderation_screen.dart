import 'package:flutter/material.dart';
import '../../../logic/event_status.dart';
import '../../../models/event_item.dart';
import '../../../models/merchandise.dart';
import '../../../models/post.dart';
import '../../../services/event_service.dart';
import '../../../services/merchandise_service.dart';
import '../../../services/post_service.dart';
import '../../../theme/app_theme.dart';
import '../events/event_form_screen.dart';
import '../merchandise/merchandise_form_screen.dart';
import 'post_form_screen.dart';

class ContentModerationScreen extends StatelessWidget {
  const ContentModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: AppTheme.card,
            child: TabBar(
              labelStyle: AppTheme.orbitron(size: 9, weight: FontWeight.w700),
              unselectedLabelStyle: AppTheme.orbitron(
                size: 9,
                weight: FontWeight.w500,
              ),
              indicatorColor: AppTheme.cyan,
              labelColor: AppTheme.cyan,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'LORE'),
                Tab(text: 'MERCH'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(children: [_PostsTab(), _MerchandiseTab()]),
          ),
        ],
      ),
    );
  }
}

// ── Posts / Lore tab ──────────────────────────────────────────────────────────

class _PostsTab extends StatefulWidget {
  const _PostsTab();

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  late final Stream<List<Post>> _posts = PostService.instance.watchPosts();
  bool _unassignedOnly = false;

  Widget _filterChip(String label, bool selected, VoidCallback onTap) =>
      ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        labelStyle: AppTheme.inter(
          size: 11,
          color: selected ? Colors.black : Colors.white70,
          weight: FontWeight.w600,
        ),
        selectedColor: AppTheme.cyan,
        backgroundColor: AppTheme.card,
        side: BorderSide(color: selected ? AppTheme.cyan : AppTheme.border),
        visualDensity: VisualDensity.compact,
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: _posts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.cyan),
          );
        }
        if (snapshot.hasError) {
          return _errorView('lore posts', snapshot.error);
        }
        final allPosts = snapshot.data ?? [];
        final unassignedCount = allPosts.where((p) => !p.hasFandom).length;
        final posts = _unassignedOnly
            ? allPosts.where((p) => !p.hasFandom).toList()
            : allPosts;
        return Column(
          children: [
            _sectionHeader(
              context,
              'Lore Posts',
              AppTheme.cyan,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostFormScreen()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  _filterChip(
                    'All (${allPosts.length})',
                    !_unassignedOnly,
                    () => setState(() => _unassignedOnly = false),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    'Unassigned ($unassignedCount)',
                    _unassignedOnly,
                    () => setState(() => _unassignedOnly = true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: posts.isEmpty
                  ? (_unassignedOnly && allPosts.isNotEmpty
                        ? _emptyView(
                            'No unassigned posts',
                            'Every post belongs to a fandom',
                          )
                        : _emptyView(
                            'No posts yet',
                            'Tap ADD to write lore content',
                          ))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: posts.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          adminPostRow(context, posts[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Admin list row for a Post (edit → PostFormScreen, delete with confirm).
/// Public so other admin screens (e.g. CategoryContentScreen) show the
/// exact same row.
Widget adminPostRow(BuildContext context, Post post) {
  return _itemCard(
    context,
    icon: Icons.article_outlined,
    iconColor: AppTheme.cyan,
    title: post.title,
    subtitle:
        '${post.category.isEmpty ? 'No category' : post.category}${post.hasFandom ? ' › ${post.fandomName}' : ''}  •  ${_fmtDate(post.createdAt)}',
    badge: post.hasFandom
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.orange, width: 0.5),
            ),
            child: Text(
              'No fandom',
              style: AppTheme.inter(size: 9, color: AppTheme.orange),
            ),
          ),
    onEdit: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostFormScreen(existing: post)),
    ),
    onDelete: () => _confirmDelete(
      context,
      'Delete "${post.title}"?',
      () => PostService.instance.deletePost(post.id),
    ),
  );
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
            child: CircularProgressIndicator(color: AppTheme.orange),
          );
        }
        if (snapshot.hasError) {
          return _errorView('merchandise', snapshot.error);
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
                  builder: (_) => const MerchandiseFormScreen(),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? _emptyView('No products yet', 'Tap ADD to list merchandise')
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          adminMerchRow(context, items[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Admin list row for a Merchandise item (edit → MerchandiseFormScreen,
/// delete with confirm). Public for reuse, like [adminPostRow].
Widget adminMerchRow(BuildContext context, Merchandise item) {
  return _itemCard(
    context,
    icon: Icons.shopping_bag_outlined,
    iconColor: AppTheme.orange,
    title: item.name,
    subtitle:
        '\$${item.price.toStringAsFixed(2)}  •  ${item.category.isEmpty ? 'No category' : item.category}',
    onEdit: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MerchandiseFormScreen(existing: item)),
    ),
    onDelete: () => _confirmDelete(
      context,
      'Delete "${item.name}"?',
      () => MerchandiseService.instance.deleteMerchandise(item.id),
    ),
  );
}

// ── Events section (standalone sidebar entry) ─────────────────────────────────

class EventsSection extends StatelessWidget {
  const EventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventItem>>(
      stream: EventService.instance.watchEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.pink),
          );
        }
        if (snapshot.hasError) {
          return _errorView('events', snapshot.error);
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
                MaterialPageRoute(builder: (_) => const EventFormScreen()),
              ),
            ),
            Expanded(
              child: events.isEmpty
                  ? _emptyView(
                      'No events yet',
                      'Tap ADD to list a convention or event',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
      subtitle: '${event.city}  •  ${_fmtDate(event.date)}  •  ${event.venue}',
      footer: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _chip(event.eventType.label, event.eventType.color, icon: event.eventType.icon),
          _statusBadge(event),
        ],
      ),
      onEdit: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventFormScreen(existing: event)),
      ),
      // Events are never hard-deleted: Unpublish hides the event from every
      // fan screen and keeps it here, where Republish brings it back.
      deleteIcon: event.isPublished
          ? Icons.visibility_off_outlined
          : Icons.visibility_outlined,
      deleteTooltip: event.isPublished ? 'Unpublish' : 'Republish',
      deleteColor: event.isPublished ? Colors.redAccent : AppTheme.cyan,
      onDelete: () => event.isPublished
          ? _confirmUnpublish(context, event)
          : _setPublished(context, event, true),
    );
  }

  Widget _statusBadge(EventItem event) {
    if (!event.isPublished) return _chip('Unpublished', Colors.grey);
    return switch (event.statusAt(DateTime.now())) {
      EventStatus.upcoming => _chip('Upcoming', AppTheme.cyan),
      EventStatus.happeningNow => _chip('Happening now', Colors.greenAccent),
      EventStatus.ended => _chip('Ended', Colors.redAccent),
    };
  }

  Widget _chip(String label, Color color, {IconData? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 11),
              const SizedBox(width: 3),
            ],
            Text(label,
                style: AppTheme.inter(size: 9, color: color, weight: FontWeight.w700)),
          ],
        ),
      );

  Future<void> _confirmUnpublish(BuildContext context, EventItem event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Unpublish "${event.title}"?',
            style: AppTheme.orbitron(size: 12, color: Colors.white)),
        content: Text(
          'Fans will no longer see it on Events, Home or its fandoms. '
          'It stays in this list and you can republish it any time.',
          style: AppTheme.inter(size: 12, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL', style: AppTheme.inter(size: 12, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('UNPUBLISH',
                style: AppTheme.inter(
                    size: 12, color: Colors.redAccent, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) await _setPublished(context, event, false);
  }

  Future<void> _setPublished(BuildContext context, EventItem event, bool published) async {
    try {
      await EventService.instance.setPublished(event.id, published);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(published
              ? '"${event.title}" is published again.'
              : '"${event.title}" is unpublished.'),
        ));
      }
    } catch (e) {
      debugPrint('Event publish change failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not update the event. Check your connection.'),
        ));
      }
    }
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _sectionHeader(
  BuildContext context,
  String title,
  Color accentColor,
  VoidCallback onAdd,
) => Padding(
  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: AppTheme.orbitron(size: 12, color: accentColor)),
      ElevatedButton.icon(
        onPressed: onAdd,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
  Widget? badge,
  // Optional line under the subtitle (an event's type and status).
  Widget? footer,
  // The right-hand action is Delete unless a caller swaps it (events use
  // Unpublish / Republish instead).
  IconData deleteIcon = Icons.delete_outline,
  String deleteTooltip = 'Delete',
  Color deleteColor = Colors.redAccent,
}) => Container(
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
            Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(size: 13, weight: FontWeight.w600),
                  ),
                ),
                if (badge != null) ...[const SizedBox(width: 6), badge],
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.inter(size: 10, color: Colors.grey),
            ),
            if (footer != null) ...[const SizedBox(height: 6), footer],
          ],
        ),
      ),
      IconButton(
        icon: const Icon(Icons.edit_outlined, color: AppTheme.cyan, size: 17),
        onPressed: onEdit,
        tooltip: 'Edit',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      const SizedBox(width: 4),
      IconButton(
        icon: Icon(deleteIcon, color: deleteColor, size: 17),
        onPressed: onDelete,
        tooltip: deleteTooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    ],
  ),
);

Widget _errorView(String what, Object? error) {
  debugPrint('Content moderation ($what) load error: $error');
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Could not load $what. Check your connection and try again.',
        style: AppTheme.inter(size: 12, color: Colors.redAccent),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Widget _emptyView(String title, String subtitle) => Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.inbox_outlined, color: Colors.grey, size: 36),
      const SizedBox(height: 12),
      Text(title, style: AppTheme.inter(size: 13, color: Colors.grey)),
      const SizedBox(height: 4),
      Text(subtitle, style: AppTheme.inter(size: 11, color: Colors.grey)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        message,
        style: AppTheme.orbitron(size: 12, color: Colors.white),
      ),
      content: Text(
        'This cannot be undone.',
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
            'DELETE',
            style: AppTheme.orbitron(size: 9, color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
  if (confirm == true) await onConfirm();
}
