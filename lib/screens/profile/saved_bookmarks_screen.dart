import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/bookmark_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bookmark_button.dart';
import '../explore/fandom_detail_screen.dart';
import 'offline_post_detail_screen.dart';

/// Saved: the signed-in user's bookmarks, read from their offline copies on
/// the device, so the list and every post open in airplane mode. On open it
/// syncs the copies with the server when there is internet.
class SavedBookmarksScreen extends StatefulWidget {
  const SavedBookmarksScreen({super.key});

  @override
  State<SavedBookmarksScreen> createState() => _SavedBookmarksScreenState();
}

class _SavedBookmarksScreenState extends State<SavedBookmarksScreen> {
  ValueListenable<Box>? _box;
  bool _syncing = true;
  bool _online = false;

  @override
  void initState() {
    super.initState();
    BookmarkStore.instance.listenable().then((l) {
      if (mounted) setState(() => _box = l);
    });
    _sync();
  }

  Future<void> _sync() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final result = await BookmarkStore.instance.sync(user.uid, user.bookmarkedPostIds);
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _online = result == BookmarkSyncResult.synced;
    });
  }

  Future<void> _remove(BookmarkCopy copy) async {
    // Captured up front: UNDO can fire after this screen is gone, so it must
    // not look anything up through this State's context.
    final messenger = ScaffoldMessenger.of(context);
    final undoContext = context;
    await setPostBookmarked(context, copy.post, false, messenger: messenger);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Removed from bookmarks'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppTheme.cyan,
          onPressed: () =>
              setPostBookmarked(undoContext, copy.post, true, messenger: messenger),
        ),
      ));
  }

  void _open(BookmarkCopy copy) {
    // Online: the normal Content Detail. Offline (or the post was taken
    // down): the saved copy.
    final page = _online && !copy.noLongerAvailable
        ? FandomDetailScreen(post: copy.post)
        : OfflinePostDetailScreen(copy: copy);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

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
        title: Text('Saved', style: AppTheme.orbitron(size: 13)),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.all(18),
              child: SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan)),
            ),
        ],
      ),
      body: ValueListenableBuilder<UserData?>(
        valueListenable: AuthService.instance.userNotifier,
        builder: (context, user, _) {
          if (user == null) {
            return _center(Icons.lock_outline, 'Sign in to see your bookmarks', '');
          }
          final box = _box;
          if (box == null) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan));
          }
          return ValueListenableBuilder<Box>(
            valueListenable: box,
            builder: (context, b, _) {
              final order = {
                for (var i = 0; i < user.bookmarkedPostIds.length; i++) user.bookmarkedPostIds[i]: i,
              };
              // Most recently bookmarked first.
              final copies = BookmarkStore.instance
                  .copiesIn(b, user.uid)
                  .where((c) => order.containsKey(c.post.id))
                  .toList()
                ..sort((a, c) => order[c.post.id]!.compareTo(order[a.post.id]!));
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(children: [
                    const Icon(Icons.offline_pin, color: AppTheme.accent, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Everything you save here is available offline.',
                          style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
                    ),
                  ]),
                  if (!_syncing && !_online) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.wifi_off, color: AppTheme.textMuted, size: 14),
                      const SizedBox(width: 6),
                      Text('Offline, showing saved copies',
                          style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                    ]),
                  ],
                  const SizedBox(height: 14),
                  if (copies.isEmpty)
                    _center(
                      Icons.bookmark_border,
                      user.bookmarkedPostIds.isEmpty ? 'No saved posts yet' : 'Downloading your saved posts…',
                      user.bookmarkedPostIds.isEmpty
                          ? 'Tap the bookmark icon on any post to save it here. Saved posts work without internet.'
                          : 'They will appear here as soon as they are on this phone.',
                    )
                  else
                    for (final c in copies) _tile(c),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _tile(BookmarkCopy c) {
    final post = c.post;
    final thumb = c.coverPath ?? c.videoThumbnailPath ?? (c.galleryPaths.isEmpty ? null : c.galleryPaths.first);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _open(c),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: thumb != null && !kIsWeb
                      ? Image.file(File(thumb),
                          fit: BoxFit.cover, errorBuilder: (ctx, e, s) => _thumbPlaceholder(post.contentType))
                      : _thumbPlaceholder(post.contentType),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    [post.contentType.toUpperCase(), if (post.fandomName.isNotEmpty) post.fandomName].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(size: 10, color: AppTheme.cyan, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 14, weight: FontWeight.w600)),
                  if (c.noLongerAvailable) ...[
                    const SizedBox(height: 6),
                    Text('No longer available online',
                        style: AppTheme.inter(size: 11, color: AppTheme.orange, weight: FontWeight.w600)),
                  ],
                ]),
              ),
              ValueListenableBuilder<Set<String>>(
                valueListenable: BookmarkStore.instance.downloading,
                builder: (context, downloading, _) => downloading.contains(post.id)
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan)),
                      )
                    : IconButton(
                        tooltip: 'Remove bookmark',
                        icon: const Icon(Icons.bookmark, color: AppTheme.cyan),
                        onPressed: () => _remove(c),
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(String type) => Container(
        color: AppTheme.bg,
        alignment: Alignment.center,
        child: Icon(
          switch (type) {
            'Video' => Icons.play_circle_outline,
            'Podcast' => Icons.headphones_rounded,
            'Gallery' => Icons.photo_library_outlined,
            _ => Icons.article_outlined,
          },
          color: Colors.white24,
        ),
      );

  Widget _center(IconData icon, String title, String subtitle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey, size: 36),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTheme.orbitron(size: 12, color: Colors.grey, weight: FontWeight.w600)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(size: 11, color: Colors.grey)),
            ],
          ],
        ),
      );
}
