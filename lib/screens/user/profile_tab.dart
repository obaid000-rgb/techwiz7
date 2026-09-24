import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.cyan]),
                  ),
                  child: const CircleAvatar(
                    radius: 46,
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80'),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppTheme.cyan, shape: BoxShape.circle),
                    child: const Icon(Icons.verified, size: 16, color: Colors.black),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Cyber Fanatic', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('fanatic@fandomverse.app', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),

          // User Stats Row
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
                _buildStatItem('14', 'Bookmarks'),
                Container(width: 1, height: 28, color: AppTheme.border),
                _buildStatItem('8', 'Events'),
                Container(width: 1, height: 28, color: AppTheme.border),
                _buildStatItem('LEVEL 5', 'Rank'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action List Options
          _buildMenuTile(Icons.bookmark_outline, 'Saved Lore Archives', () {}),
          _buildMenuTile(Icons.notifications_none, 'Push Notifications', () {}),
          _buildMenuTile(Icons.security, 'Account Security', () {}),
          const SizedBox(height: 20),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
              label: const Text('LOG OUT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.cyan)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.cyan, size: 20),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        onTap: onTap,
      ),
    );
  }
}
