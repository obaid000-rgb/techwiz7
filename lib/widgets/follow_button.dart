import 'package:flutter/material.dart';
import '../screens/shop/shop_tab.dart' show showGuestLoginSheet;
import '../services/auth_service.dart';
import '../services/fandom_service.dart';
import '../services/xp_service.dart';
import '../theme/app_theme.dart';

class FollowButton extends StatefulWidget {
  final String fandomId;
  final bool compact;
  const FollowButton({super.key, required this.fandomId, this.compact = false});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _busy = false;
  DateTime? _lastTap;

  void _setFollowed(bool followed) {
    final current = AuthService.instance.currentUser;
    if (current == null) return;
    final ids = List<String>.from(current.followedFandomIds)
      ..remove(widget.fandomId);
    if (followed) ids.add(widget.fandomId);
    AuthService.instance.userNotifier.value =
        current.copyWith(followedFandomIds: ids);
  }

  Future<void> _toggle() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      showGuestLoginSheet(context, feature: 'Following fandoms');
      return;
    }
    final now = DateTime.now();
    if (_busy ||
        (_lastTap != null &&
            now.difference(_lastTap!) < const Duration(milliseconds: 500))) {
      return;
    }
    _lastTap = now;
    final messenger = ScaffoldMessenger.of(context);
    final wasFollowing = user.followedFandomIds.contains(widget.fandomId);
    if (!wasFollowing &&
        user.followedFandomIds.length >= FandomService.maxFollowed) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('You can follow up to 30 fandoms.')));
      return;
    }

    setState(() => _busy = true);
    _setFollowed(!wasFollowing);
    try {
      if (wasFollowing) {
        await FandomService.instance.unfollow(user.uid, widget.fandomId);
      } else {
        await FandomService.instance.follow(user.uid, widget.fandomId);
        XpService.instance.award(XpAction.firstFollow, targetId: widget.fandomId);
      }
    } catch (e) {
      debugPrint('Follow update failed: $e');
      _setFollowed(wasFollowing);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(e is FandomException
              ? e.message
              : 'Could not update. Check your connection and try again.'),
        ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserData?>(
      valueListenable: AuthService.instance.userNotifier,
      builder: (context, user, _) {
        final following =
            user?.followedFandomIds.contains(widget.fandomId) ?? false;
        final label = following ? 'Following' : 'Follow';
        final icon = following ? Icons.check_rounded : Icons.add_rounded;
        final size = widget.compact ? 11.0 : 12.5;
        final padding = widget.compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
        final shape =
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
        final text = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: size + 3),
            const SizedBox(width: 4),
            Text(label,
                style: AppTheme.inter(
                    size: size,
                    weight: FontWeight.w700,
                    color: following ? AppTheme.cyan : Colors.black)),
          ],
        );
        return Semantics(
          button: true,
          toggled: following,
          child: following
              ? OutlinedButton(
                  onPressed: _toggle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cyan,
                    side: const BorderSide(color: AppTheme.cyan),
                    padding: padding,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: shape,
                  ),
                  child: text,
                )
              : ElevatedButton(
                  onPressed: _toggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cyan,
                    foregroundColor: Colors.black,
                    padding: padding,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: shape,
                  ),
                  child: text,
                ),
        );
      },
    );
  }
}
