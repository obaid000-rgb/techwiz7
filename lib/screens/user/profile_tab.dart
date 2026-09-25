import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/guest_prompt.dart';
import '../../widgets/image_upload_field.dart';
import 'offline_downloads_screen.dart';
import 'post_list_screen.dart';

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
  Future<void> _onAvatarUploaded(String url) async {
    final updated = widget.user.copyWith(avatarUrl: url);
    try {
      await UserService.instance.updateUser(updated);
    } catch (_) {}
    AuthService.instance.userNotifier.value = updated;
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
    if (result == null) return;
    final updated = widget.user.copyWith(bio: result);
    try {
      await UserService.instance.updateUser(updated);
    } catch (_) {}
    AuthService.instance.userNotifier.value = updated;
  }

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
                _stat('${user.bookmarkedPostIds.length}', 'Liked'),
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
            'Liked Fandoms',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostListScreen(
                  title: 'Liked Fandoms',
                  stream: PostService.instance.watchPosts().map((posts) => posts
                      .where((p) => user.bookmarkedPostIds.contains(p.id))
                      .toList()),
                  emptyMessage:
                      'No liked fandoms yet — bookmark posts from Home to see them here.',
                ),
              ),
            ),
          ),
          _menuTile(
            Icons.download_for_offline_outlined,
            'Downloads',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OfflineDownloadsScreen()),
            ),
          ),
          _menuTile(Icons.notifications_none, 'Push Notifications', () {}),
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

  Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
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
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        onTap: onTap,
      ),
    );
  }
}
