import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../utils/validators.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _submitted = true);
      return;
    }
    setState(() { _loading = true; _errorMessage = null; });
    try {
      await AuthService.instance.signIn(
        email: _emailController.text,
        password: _passController.text,
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = _friendlyError(e.code); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final signedIn = await AuthService.instance.signInWithGoogle();
      // Closing the Google account picker is not a login: stay here.
      if (signedIn && mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Google Exception: Code: ${e.code}, Message: ${e.message}");
      if (!mounted) return;
      setState(() { _errorMessage = _friendlyError(e.code); });
    } catch (e, stack) {
      debugPrint("Detailed Google Sign-In Failure Object: $e");
      debugPrint("Stacktrace: $stack");
      if (!mounted) return;
      setState(() { _errorMessage = _googleError(e); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect email or password.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your connection and try again.';
      case 'account-exists-with-different-credential':
        return 'This email already has an account. Log in with your email and password.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  /// google_sign_in reports failures as PlatformException text containing
  /// Google Play Services' ApiException status code.
  String _googleError(Object e) {
    final s = e.toString();
    if (s.contains('network_error') || s.contains('ApiException: 7')) {
      return 'No internet connection. Check your connection and try again.';
    }
    if (s.contains('ApiException: 10')) {
      // DEVELOPER_ERROR: this build's SHA-1 isn't registered in Firebase.
      return 'Google sign-in isn\'t set up for this build yet. Please log in with email for now.';
    }
    if (s.contains('sign_in_canceled') || s.contains('ApiException: 12501')) {
      return 'Google sign-in was cancelled.';
    }
    return 'Google sign-in failed. Please try again or log in with email.';
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogo(size: 60)),
                      const SizedBox(height: 20),
                      const Text('FANDOM VERSE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2)),
                      const Text('ACCESS YOUR ACCOUNT',
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
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!,
                                    style: AppTheme.inter(
                                        size: 12, color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _emailController,
                        validator: Validators.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          prefixIcon:
                              Icon(Icons.email_outlined, color: Colors.grey),
                          hintText: 'Email Address',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passController,
                        obscureText: _hidePassword,
                        validator: Validators.validateLoginPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.lock_outline, color: Colors.grey),
                          hintText: 'Password',
                          suffixIcon: IconButton(
                            tooltip: _hidePassword ? 'Show password' : 'Hide password',
                            icon: Icon(
                                _hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Colors.grey),
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                  initialEmail: _emailController.text.trim()),
                            ),
                          ),
                          child: const Text('Forgot Password?',
                              style: TextStyle(
                                  color: AppTheme.cyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 8),

                      ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cyan,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _loading && _emailController.text.isNotEmpty
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black))
                            : const Text('LOG IN',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),

                      const Row(
                        children: [
                          Expanded(child: Divider(color: AppTheme.border)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Expanded(child: Divider(color: AppTheme.border)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      OutlinedButton.icon(
                        onPressed: _loading ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          backgroundColor: AppTheme.card,
                        ),
                        icon: _loading && _emailController.text.isEmpty
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.g_mobiledata,
                                color: Colors.white, size: 24),
                        label: const Text('Continue with Google',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13)),
                          GestureDetector(
                            // Replace (not push) so Login and Register swap
                            // in place; after registering, Register's pop
                            // returns to where the user started.
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignupScreen()),
                            ),
                            child: const Text('Sign Up',
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
    );
  }
}
