import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../admin/views/admin_shell.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../explore_tab.dart';
import 'home_tab.dart';
import 'lore_tab.dart';
import 'onboarding_screen.dart';
import 'profile_tab.dart';
import 'shop_tab.dart';

class FanHomeScreen extends StatefulWidget {
  const FanHomeScreen({super.key});

  @override
  State<FanHomeScreen> createState() => _FanHomeScreenState();
}

class _FanHomeScreenState extends State<FanHomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAIAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AiAssistantSheet(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(_currentIndex == 0 ? 120 : 68),
      // BackdropFilter creates the glass/blur effect; content behind shows through
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF151725).withValues(alpha: 0.75),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // ── Logo row ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        // 32×32 rounded-square logo, purple→cyan diagonal gradient
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [AppTheme.accent, AppTheme.cyan],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'F',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Wordmark + caption
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ShaderMask applies a horizontal gradient over the text color
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [AppTheme.cyan, AppTheme.accent, AppTheme.pink],
                              ).createShader(bounds),
                              child: Text(
                                'FANDOM VERSE',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            Text(
                              'POCKET EDITION',
                              style: GoogleFonts.orbitron(
                                color: Colors.blueGrey,
                                fontSize: 7,
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Auth-aware right side: guest shows Log In + Register;
                        // signed-in shows the role badge (the profile lives in the Profile tab)
                        ValueListenableBuilder<UserData?>(
                          valueListenable: AuthService.instance.userNotifier,
                          builder: (context, user, _) {
                            if (user == null) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    child: Text('Log In',
                                        style: AppTheme.inter(size: 12, weight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: const LinearGradient(
                                          colors: [AppTheme.accent, AppTheme.cyan],
                                        ),
                                      ),
                                      child: Text('Register',
                                          style: AppTheme.inter(
                                              size: 11, weight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              );
                            }
                            // Signed-in: role badge + optional admin button
                            final isAdmin = user.role == 'admin';
                            final badgeColor = isAdmin ? AppTheme.orange : AppTheme.cyan;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Role badge — shows ADMIN (orange) or FAN (cyan)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.card,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: isAdmin
                                            ? AppTheme.orange.withValues(alpha: 0.6)
                                            : AppTheme.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield_outlined, color: badgeColor, size: 12),
                                      const SizedBox(width: 4),
                                      Text(isAdmin ? 'ADMIN' : 'FAN',
                                          style: GoogleFonts.orbitron(
                                            color: badgeColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          )),
                                    ],
                                  ),
                                ),
                                // Admin panel entry — only renders for admin role
                                if (isAdmin) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const AdminShell()),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppTheme.orange.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppTheme.orange.withValues(alpha: 0.5)),
                                      ),
                                      child: const Icon(Icons.admin_panel_settings,
                                          color: AppTheme.orange, size: 16),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // ── Search bar (Home only — it filters Home's posts) ──
                  if (_currentIndex == 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        style: AppTheme.inter(color: Colors.white, size: 14),
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search posts on Home',
                          hintStyle: AppTheme.inter(color: AppTheme.textMuted, size: 14),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                          filled: true,
                          fillColor: AppTheme.card.withValues(alpha: 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.cyan, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserData?>(
      valueListenable: AuthService.instance.userNotifier,
      builder: (context, user, _) {
        // Safety net: any signed-in account with no saved categories (e.g.
        // pre-migration accounts, or registered with no pending pre-login
        // selection on this device) picks interests + badge here.
        if (user != null && !user.hasOnboarded) {
          return OnboardingScreen(user: user);
        }
        return _buildTabs(context);
      },
    );
  }

  Widget _buildTabs(BuildContext context) {
    final List<Widget> tabs = [
      HomeTab(searchQuery: _searchQuery),
      const LoreTab(),
      const ExploreTab(),
      const ShopTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(index: _currentIndex, children: tabs),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _openAIAssistant,
              tooltip: 'Fandom AI Assistant',
              backgroundColor: Colors.transparent,
              elevation: 8,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.cyan, AppTheme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 26),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) => AppTheme.inter(
                size: 11,
                weight: FontWeight.w600,
                color: states.contains(WidgetState.selected) ? Colors.white : AppTheme.textMuted,
              )),
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
                size: 24,
                color: states.contains(WidgetState.selected) ? Colors.white : AppTheme.textMuted,
              )),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppTheme.bg,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppTheme.accent.withValues(alpha: 0.28),
          height: 68,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Lore'),
            NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

/// The AI Assistant sheet: same header and input as before, now with a real
/// conversation. The session lives in [AiAssistantService] for as long as the
/// app is open, so closing and reopening the sheet keeps the chat.
class _AiAssistantSheet extends StatefulWidget {
  const _AiAssistantSheet();

  @override
  State<_AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<_AiAssistantSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _service = AiAssistantService.instance;
  bool _waiting = false;
  String? _error;
  String? _failedText;

  static const _suggestions = [
    'How do I find events near me?',
    'How do price alerts work?',
    'Where are my bookmarks?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _waiting) return;
    _input.clear();
    setState(() {
      _waiting = true;
      _error = null;
      _failedText = null;
    });
    _scrollToEnd();
    try {
      await _service.ask(text);
    } on AiAssistantException catch (e) {
      _error = e.message;
      _failedText = text;
    }
    if (!mounted) return;
    setState(() => _waiting = false);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final transcript = _service.transcript;
    // While waiting, the question is already in the transcript; on failure
    // it's removed again and shown in the error row with Retry instead.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppTheme.cyan, shape: BoxShape.circle),
                    child: const Icon(Icons.smart_toy, color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fandom AI Assistant', style: AppTheme.orbitron(size: 14, weight: FontWeight.w700)),
                        Text('Ask how anything in Fandom Verse works',
                            style: AppTheme.inter(size: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (transcript.isNotEmpty)
                    IconButton(
                      tooltip: 'New chat',
                      onPressed: _waiting
                          ? null
                          : () => setState(() {
                                _service.reset();
                                _error = null;
                                _failedText = null;
                              }),
                      icon: const Icon(Icons.refresh, color: AppTheme.textMuted, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: transcript.isEmpty && !_waiting && _error == null
                    ? _intro()
                    : ListView(
                        controller: _scroll,
                        shrinkWrap: true,
                        children: [
                          for (final m in transcript) _bubble(m.text, fromUser: m.fromUser),
                          if (_waiting) _typing(),
                          if (_error != null) _errorRow(),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _input,
                enabled: !_waiting,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                minLines: 1,
                maxLines: 4,
                style: AppTheme.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., How do I find events near me?',
                  suffixIcon: IconButton(
                    tooltip: 'Send',
                    icon: const Icon(Icons.send, color: AppTheme.cyan),
                    onPressed: _waiting ? null : () => _send(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _intro() => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('I can help you find your way around the app. Try:',
                style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _suggestions)
                  ActionChip(
                    label: Text(s, style: AppTheme.inter(size: 12, color: Colors.white)),
                    backgroundColor: AppTheme.bg,
                    side: const BorderSide(color: AppTheme.border),
                    onPressed: () => _send(s),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _bubble(String text, {required bool fromUser}) => Align(
        alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: fromUser ? AppTheme.accent.withValues(alpha: 0.35) : AppTheme.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: fromUser ? AppTheme.accent.withValues(alpha: 0.6) : AppTheme.border),
          ),
          child: SelectableText(text, style: AppTheme.inter(size: 13, color: Colors.white, height: 1.4)),
        ),
      );

  Widget _typing() => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
                width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan)),
            const SizedBox(width: 10),
            Text('Thinking…', style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
          ]),
        ),
      );

  Widget _errorRow() => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: AppTheme.inter(size: 12, color: Colors.redAccent))),
          if (_failedText != null)
            TextButton(
              onPressed: () => _send(_failedText),
              child: Text('Retry', style: AppTheme.inter(size: 12, weight: FontWeight.w700, color: AppTheme.cyan)),
            ),
        ]),
      );
}
