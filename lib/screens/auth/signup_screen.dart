import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../user/fan_home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  void _signup() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FanHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=800&q=80',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay for readability
          Positioned.fill(
            child: Container(
              color: AppTheme.bg.withValues(alpha: 0.88),
            ),
          ),
          // Form Content
          SafeArea(
            child: Column(
              children: [
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.pink, AppTheme.accent],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accent.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.person_add_alt_1, color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'CREATE ACCOUNT',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            const Text(
                              'JOIN THE FANDOM VERSE NETWORK',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.cyan,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _nameController,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Full Name required' : null,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                                hintText: 'Full Name',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              validator: Validators.validateEmail,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                                hintText: 'Email Address',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passController,
                              obscureText: true,
                              validator: Validators.validatePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                                hintText: 'Password',
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'REGISTER NOW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Already have an account? ",
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text(
                                    'Log In',
                                    style: TextStyle(
                                      color: AppTheme.cyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
