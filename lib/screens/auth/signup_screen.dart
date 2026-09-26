import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/first_run_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

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
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMessage = null; });
    try {
      await AuthService.instance.register(
        email: _emailController.text,
        password: _passController.text,
        name: _nameController.text,
      );
      await _applyPendingSelection();
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = _friendlyError(e.code); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  // Registration-only: a brand-new account adopts the interests + badge picked
  // before login on this device (LoginScreen deliberately never reads them —
  // an existing account's saved data always wins). The pending selection is
  // cleared once written so it can't attach to a later account. If there is
  // none, or the write fails, the account keeps empty categories and
  // FanHomeScreen's Select Fandoms fallback asks instead.
  Future<void> _applyPendingSelection() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final pending = await FirstRunService.instance.readPending();
    if (pending == null) return;
    AuthService.instance.userNotifier.value =
        user.copyWith(categories: pending.categories, badge: pending.badge);
    try {
      await UserService.instance
          .setInterestsAndBadge(user.uid, pending.categories, pending.badge);
      await FirstRunService.instance.clearPending();
    } catch (_) {
      AuthService.instance.userNotifier.value = user;
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Sign-up is not available right now. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your connection and try again.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=800&q=80',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: AppTheme.bg.withValues(alpha: 0.88)),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
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
                                      color:
                                          AppTheme.accent.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.person_add_alt_1,
                                      color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text('CREATE ACCOUNT',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2)),
                            const Text('JOIN THE FANDOM VERSE NETWORK',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.cyan,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 32),

                            // Error banner
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.redAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.redAccent
                                          .withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.redAccent, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(_errorMessage!,
                                          style: AppTheme.inter(
                                              size: 12,
                                              color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            TextFormField(
                              controller: _nameController,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Full Name required'
                                  : null,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline,
                                    color: Colors.grey),
                                hintText: 'Full Name',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              validator: Validators.validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.email_outlined,
                                    color: Colors.grey),
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
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: Colors.grey),
                                hintText: 'Password',
                              ),
                            ),
                            const SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: _loading ? null : _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('REGISTER NOW',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? ',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text('Log In',
                                      style: TextStyle(
                                          color: AppTheme.cyan,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
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
