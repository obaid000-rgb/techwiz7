import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/guest_prompt.dart';
import '../../widgets/image_upload_field.dart';

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
    final u = widget.user;
    final updated = UserData(
      uid: u.uid,
      name: u.name,
      email: u.email,
      avatarUrl: url,
      savedEvents: u.savedEvents,
      bookmarks: u.bookmarks,
      rank: u.rank,
      role: u.role,
      categories: u.categories,
    );
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
          const SizedBox(height: 24),

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
                _stat('${user.bookmarks}', 'Bookmarks'),
                Container(width: 1, height: 28, color: AppTheme.border),
                _stat('${user.savedEvents}', 'Events'),
                Container(width: 1, height: 28, color: AppTheme.border),
                _stat(user.rank, 'Rank'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _menuTile(Icons.bookmark_outline, 'Saved Lore Archives', () {}),
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
