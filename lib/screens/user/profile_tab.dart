import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../services/auth_service.dart';
import '../../services/category_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/guest_prompt.dart';
import '../../widgets/image_upload_field.dart';
import '../../widgets/my_fandoms_card.dart';
import 'notifications_screen.dart';
import 'offline_downloads_screen.dart';
import 'purchase_history_screen.dart';
import 'saved_bookmarks_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserData?>(
      valueListenable: AuthService.instance.userNotifier,
      builder: (context, user, _) {
        if (user == null) {
          return const GuestPrompt(feature: 'Your profile and saved content');
        }
        return _ProfileContent(user: user);
      },
    );
  }
}

class _ProfileContent extends StatefulWidget {
  final UserData user;
  const _ProfileContent({required this.user});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  late final Stream<List<AppCategory>> _categories =
      CategoryService.instance.watchCategories();

  /// Shows [apply] immediately, writes it with [save] (a single-field
  /// Firestore update), and rolls back with a message if the write fails.
  Future<void> _saveField(
    UserData Function(UserData u) apply,
    UserData Function(UserData u) revert,
    Future<void> Function(String uid) save,
    String failMessage,
  ) async {
    final user = AuthService.instance.currentUser ?? widget.user;
    AuthService.instance.userNotifier.value = apply(user);
    try {
      await save(user.uid);
    } catch (_) {
      final current = AuthService.instance.currentUser;
      if (current != null) AuthService.instance.userNotifier.value = revert(current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failMessage)));
      }
    }
  }

  Future<void> _onAvatarUploaded(String url) {
    final previous = widget.user.avatarUrl;
    return _saveField(
      (u) => u.copyWith(avatarUrl: url),
      (u) => u.copyWith(avatarUrl: previous),
      (uid) => UserService.instance.setAvatarUrl(uid, url),
      'Could not save your new avatar. Try again.',
    );
  }

  Future<void> _editBio() async {
    final ctrl = TextEditingController(text: widget.user.bio);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Bio', style: AppTheme.orbitron(size: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              maxLength: 160,
              style: AppTheme.inter(size: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tell other fans a bit about yourself…',
                filled: true,
                fillColor: AppTheme.bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.border)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('SAVE',
                    style: AppTheme.orbitron(size: 10, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == null || result == widget.user.bio) return;
    final previous = widget.user.bio;
    await _saveField(
      (u) => u.copyWith(bio: result),
      (u) => u.copyWith(bio: previous),
      (uid) => UserService.instance.setBio(uid, result),
      'Could not save your bio. Try again.',
    );
  }

  Future<void> _editFandoms(List<AppCategory> allCategories) async {
    final active = allCategories.where((c) => c.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final selected = Set<String>.from(widget.user.categories);
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Fandoms', style: AppTheme.orbitron(size: 13)),
                const SizedBox(height: 4),
                Text('Pick the fandoms you follow. Used to tailor your feed.',
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
                const SizedBox(height: 14),
                if (active.isEmpty)
                  Text('No categories available yet.',
                      style: AppTheme.inter(size: 12, color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: active.map((c) {
                      final on = selected.contains(c.key);
                      return FilterChip(
                        label: Text(c.name),
                        selected: on,
                        onSelected: (v) => setSheet(() {
                          v ? selected.add(c.key) : selected.remove(c.key);
                        }),
                        showCheckmark: true,
                        checkmarkColor: Colors.white,
                        selectedColor: AppTheme.accent.withValues(alpha: 0.35),
                        backgroundColor: AppTheme.bg,
                        side: BorderSide(color: on ? AppTheme.accent : AppTheme.border),
                        labelStyle: AppTheme.inter(
                            size: 12,
                            color: on ? Colors.white : Colors.white70,
                            weight: on ? FontWeight.w700 : FontWeight.w400),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // At least one is required — an empty list would send the
                    // user back through the Select Fandoms screen.
                    onPressed: selected.isEmpty ? null : () => Navigator.pop(ctx, selected.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      disabledBackgroundColor: AppTheme.border,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(selected.isEmpty ? 'PICK AT LEAST ONE' : 'SAVE',
                        style: AppTheme.orbitron(size: 10, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null) return;
    final previous = List<String>.from(widget.user.categories);
    await _saveField(
      (u) => u.copyWith(categories: result),
      (u) => u.copyWith(categories: previous),
      (uid) => UserService.instance.setCategories(uid, result),
      'Could not save your fandoms. Try again.',
    );
  }

  Widget _fandomsCard(UserData user) => StreamBuilder<List<AppCategory>>(
        stream: _categories,
        builder: (context, snapshot) => MyFandomsCard(
          categoryKeys: user.categories,
          categories: snapshot.data,
          hasError: snapshot.hasError,
          onEdit: snapshot.hasData ? () => _editFandoms(snapshot.data!) : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          ImageUploadField(
            initialUrl: user.avatarUrl.isEmpty ? null : user.avatarUrl,
            onUploaded: _onAvatarUploaded,
            accentColor: AppTheme.cyan,
            isCircular: true,
            circleRadius: 46,
          ),
          const SizedBox(height: 14),
          Text(user.name,
              style: AppTheme.orbitron(size: 18, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(user.email, style: AppTheme.inter(size: 12, color: Colors.grey)),
          if (user.badge.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.military_tech, color: AppTheme.cyan, size: 13),
                  const SizedBox(width: 5),
                  Text(user.badge,
                      style: AppTheme.orbitron(size: 9, color: AppTheme.cyan)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Bio
          GestureDetector(
            onTap: _editBio,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      user.bio.isEmpty ? 'Add a bio…' : user.bio,
                      style: AppTheme.inter(
                        size: 12,
                        color: user.bio.isEmpty ? Colors.grey : Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_outlined, color: Colors.grey, size: 15),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _fandomsCard(user),
          const SizedBox(height: 20),

          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('${user.bookmarkedPostIds.length}', 'Saved'),
                Container(width: 1, height: 28, color: AppTheme.border),
                _stat('${user.savedEvents}', 'Events'),
                Container(width: 1, height: 28, color: AppTheme.border),
                _stat(user.rank, 'Rank'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _menuTile(
            Icons.bookmark_outline,
            'Saved Bookmarks',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedBookmarksScreen()),
            ),
            subtitle: 'Synced to your account · needs internet',
          ),
          _menuTile(
            Icons.receipt_long_outlined,
            'Purchase History',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PurchaseHistoryScreen(uid: user.uid)),
            ),
          ),
          _menuTile(
            Icons.download_for_offline_outlined,
            'Offline Downloads',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OfflineDownloadsScreen()),
            ),
            subtitle: 'Saved on this device · works without internet',
          ),
          _menuTile(
            Icons.notifications_none,
            'Push Notifications',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          _menuTile(Icons.security, 'Account Security', () {}),
          const SizedBox(height: 20),

          // Logout — calls signOut() only; top bar and this screen update via ValueListenableBuilder
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => AuthService.instance.signOut(),
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
              label: Text('LOG OUT',
                  style: AppTheme.orbitron(size: 11, color: Colors.redAccent, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String val, String label) {
    return Column(
      children: [
        Text(val, style: AppTheme.orbitron(size: 14, color: AppTheme.cyan, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.inter(size: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap, {String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.cyan, size: 20),
        title: Text(title, style: AppTheme.inter(size: 13)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, style: AppTheme.inter(size: 10, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        onTap: onTap,
      ),
    );
  }
}
