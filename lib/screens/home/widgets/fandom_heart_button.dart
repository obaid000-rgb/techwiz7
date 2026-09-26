import 'package:flutter/material.dart';
import '../../shop/shop_tab.dart' show showGuestLoginSheet;
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../theme/app_theme.dart';

/// Heart that adds/removes a category in the signed-in user's interests
/// (UserData.categories — the same list shown in Profile → My Fandoms).
/// [compact] is the small inline version used inside chips.
class FandomHeartButton extends StatelessWidget {
  final String categoryKey;
  final String categoryName;
  final bool compact;

  const FandomHeartButton({
    super.key,
    required this.categoryKey,
    required this.categoryName,
    this.compact = false,
  });

  Future<void> _toggle(BuildContext context) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      showGuestLoginSheet(context, feature: 'Your fandoms');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final following = user.categories.contains(categoryKey);
    // An empty interest list would send the user back through Select Fandoms.
    if (following && user.categories.length == 1) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Keep at least one fandom. Add another first, or edit them in Profile.'),
        ));
      return;
    }
    final updated = List<String>.from(user.categories);
    following ? updated.remove(categoryKey) : updated.add(categoryKey);
    AuthService.instance.userNotifier.value = user.copyWith(categories: updated);
    try {
      await UserService.instance.setCategoryFollowed(user.uid, categoryKey, !following);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(following
              ? 'Removed $categoryName from My Fandoms'
              : 'Added $categoryName to My Fandoms'),
          duration: const Duration(seconds: 2),
        ));
    } catch (_) {
      final current = AuthService.instance.currentUser;
      if (current != null) {
        final reverted = List<String>.from(current.categories);
        following ? reverted.add(categoryKey) : reverted.remove(categoryKey);
        AuthService.instance.userNotifier.value =
            current.copyWith(categories: reverted.toSet().toList());
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update your fandoms. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserData?>(
      valueListenable: AuthService.instance.userNotifier,
      builder: (context, user, _) {
        final following = user?.categories.contains(categoryKey) ?? false;
        final tooltip = following ? 'Remove from My Fandoms' : 'Add to My Fandoms';
        final icon = AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Icon(
            following ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(following),
            color: following ? AppTheme.pink : Colors.white,
            size: compact ? 14 : 18,
          ),
        );
        return Semantics(
          button: true,
          label: tooltip,
          child: Tooltip(
            message: tooltip,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggle(context),
              child: compact
                  // Padding widens the tap target without changing the chip.
                  ? Padding(padding: const EdgeInsets.all(4), child: icon)
                  : Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: following
                            ? AppTheme.pink.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.55),
                        border: Border.all(
                          color: following
                              ? AppTheme.pink.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: icon,
                    ),
            ),
          ),
        );
      },
    );
  }
}
