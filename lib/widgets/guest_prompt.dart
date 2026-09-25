import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../theme/app_theme.dart';

/// Reusable gate shown on any personal screen when the user is not signed in.
/// Tapping either button pushes the auth screen; after it pops the caller's
/// ValueListenableBuilder rebuilds automatically — no extra callback needed.
class GuestPrompt extends StatelessWidget {
  final String feature;
  const GuestPrompt({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(   
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.lock_outline, color: AppTheme.cyan, size: 36),
            ),
            const SizedBox(height: 22),
            Text(
              'Sign In Required',
              style: AppTheme.orbitron(size: 16, weight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '$feature requires an account.\nCreate one free or sign into an existing account.',
              style: AppTheme.inter(size: 13, color: Colors.grey, height: 1.55),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'LOG IN',
                  style: AppTheme.orbitron(size: 12, color: Colors.black, weight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'CREATE ACCOUNT',
                  style: AppTheme.orbitron(size: 12, color: AppTheme.accent, weight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
