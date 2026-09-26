import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lore_card.dart';

/// The signed-in user's live bookmarks (users/{uid}.bookmarkedPostIds). Needs
/// a connection — for reading without internet see Offline Downloads.
class SavedBookmarksScreen extends StatefulWidget {
  const SavedBookmarksScreen({super.key});

  @override
  State<SavedBookmarksScreen> createState() => _SavedBookmarksScreenState();
}

class _SavedBookmarksScreenState extends State<SavedBookmarksScreen> {
  late final Stream<List<Post>> _posts = PostService.instance.watchActivePosts();

  Future<void> _setBookmarked(UserData user, String postId, bool bookmarked) async {
    final ids = List<String>.from(user.bookmarkedPostIds);
    bookmarked ? ids.add(postId) : ids.remove(postId);
    AuthService.instance.userNotifier.value = user.copyWith(bookmarkedPostIds: ids);
    try {
      await UserService.instance.setBookmarked(user.uid, postId, bookmarked);
      if (!bookmarked && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: const Text('Removed from bookmarks'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppTheme.cyan,
              onPressed: () {
                final current = AuthService.instance.currentUser;
                if (current != null) _setBookmarked(current, postId, true);
              },
            ),
          ));
      }
    } catch (_) {
      final current = AuthService.instance.currentUser;
      if (current != null) {
        final reverted = List<String>.from(current.bookmarkedPostIds);
        bookmarked ? reverted.remove(postId) : reverted.add(postId);
        AuthService.instance.userNotifier.value =
            current.copyWith(bookmarkedPostIds: reverted.toSet().toList());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update bookmarks. Try again.')),
        );
      }
    }
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
        title: Text('Saved Bookmarks', style: AppTheme.orbitron(size: 13)),
      ),
      body: ValueListenableBuilder<UserData?>(
        valueListenable: AuthService.instance.userNotifier,
        builder: (context, user, _) {
          if (user == null) {
            return _center(Icons.lock_outline, 'Sign in to see your bookmarks', '');
          }
          return StreamBuilder<List<Post>>(
            stream: _posts,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _center(Icons.wifi_off, 'Could not load bookmarks',
                    'Bookmarks need a connection. Offline Downloads work without one.');
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan));
              }
              final byId = {for (final p in snapshot.data!) p.id: p};
              // Most recently bookmarked first; hidden/deleted posts skipped.
              final posts = [
                for (final id in user.bookmarkedPostIds.reversed)
                  if (byId[id] != null) byId[id]!,
              ];
              if (posts.isEmpty) {
                return _center(Icons.bookmark_border, 'No saved bookmarks yet',
                    'Tap the bookmark icon on any post in Feed to save it here.');
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, i) => Stack(
                  children: [
                    LoreCard(post: posts[i]),
                    // Same filled bookmark button as Home's post cards.
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _setBookmarked(user, posts[i].id, false),
                        child: Tooltip(
                          message: 'Remove bookmark',
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.cyan,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bookmark, color: Colors.black, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _center(IconData icon, String title, String subtitle) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
        ),
      );
}
