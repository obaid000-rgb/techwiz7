import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/bookmark_store.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

/// Bookmark or unbookmark [post] (signed-in users only, as before). A
/// bookmark is also an offline copy: bookmarking saves the post and its
/// files on the device, removing it deletes them.
///
/// Pass [messenger] when calling from somewhere [context] may no longer be
/// mounted (e.g. a snackbar's UNDO); the bookmark write still happens even
/// when there is nowhere left to show a message.
Future<void> setPostBookmarked(BuildContext context, Post post, bool bookmark,
    {ScaffoldMessengerState? messenger}) async {
  final user = AuthService.instance.currentUser;
  messenger ??= context.mounted ? ScaffoldMessenger.maybeOf(context) : null;
  if (user == null) {
    messenger?.showSnackBar(const SnackBar(content: Text('Log in to bookmark posts.')));
    return;
  }
  if (user.bookmarkedPostIds.contains(post.id) == bookmark) return;
  final ids = List<String>.from(user.bookmarkedPostIds);
  bookmark ? ids.add(post.id) : ids.remove(post.id);
  AuthService.instance.userNotifier.value = user.copyWith(bookmarkedPostIds: ids);
  try {
    await UserService.instance.setBookmarked(user.uid, post.id, bookmark);
  } catch (e) {
    debugPrint('Bookmark update failed: $e');
    final current = AuthService.instance.currentUser;
    if (current != null) {
      final reverted = List<String>.from(current.bookmarkedPostIds);
      bookmark ? reverted.remove(post.id) : reverted.add(post.id);
      AuthService.instance.userNotifier.value =
          current.copyWith(bookmarkedPostIds: reverted.toSet().toList());
    }
    messenger?.showSnackBar(const SnackBar(content: Text('Could not update bookmarks. Try again.')));
    return;
  }
  try {
    if (bookmark) {
      // Files that fail to download are retried at the next sync; the
      // bookmark itself stays either way.
      await BookmarkStore.instance.save(user.uid, post);
    } else {
      await BookmarkStore.instance.remove(user.uid, post.id);
    }
  } catch (e) {
    debugPrint('Bookmark copy update failed: $e');
  }
}

/// The bookmark icon on post cards. While the post's files download it
/// shows a small progress ring over the filled bookmark.
class BookmarkButton extends StatelessWidget {
  final Post post;
  const BookmarkButton({super.key, required this.post});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UserData?>(
        valueListenable: AuthService.instance.userNotifier,
        builder: (context, user, _) => ValueListenableBuilder<Set<String>>(
          valueListenable: BookmarkStore.instance.downloading,
          builder: (context, downloading, _) {
            final saved = user?.bookmarkedPostIds.contains(post.id) ?? false;
            final busy = saved && downloading.contains(post.id);
            return SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                tooltip: busy
                    ? 'Saving for offline…'
                    : saved
                        ? 'Remove bookmark'
                        : 'Bookmark (saves for offline)',
                onPressed: () => setPostBookmarked(context, post, !saved),
                icon: Stack(alignment: Alignment.center, children: [
                  Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                      color: saved ? AppTheme.cyan : AppTheme.textSecondary, size: 22),
                  if (busy)
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
                    ),
                ]),
              ),
            );
          },
        ),
      );
}
