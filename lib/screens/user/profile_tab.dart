import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../landing_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final initial = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName![0].toUpperCase() : 'F';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF8B5CF6),
              child: Text(initial, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user?.displayName ?? 'Fan',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Center(
              child: Text(user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
            const SizedBox(height: 32),
            const _ProfileMenuItem(icon: Icons.favorite_outline, label: 'Liked Fandoms', phase: 'Phase 3'),
            const _ProfileMenuItem(icon: Icons.bookmark_outline, label: 'Saved Bookmarks', phase: 'Phase 6'),
            const _ProfileMenuItem(icon: Icons.history, label: 'Purchase History', phase: 'Phase 5'),
            const Spacer(),
            OutlinedButton(
              onPressed: () => _logout(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String phase;

  const _ProfileMenuItem({required this.icon, required this.label, required this.phase});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white70),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: Text(phase, style: const TextStyle(color: Colors.white38, fontSize: 12)),
    );
  }
}