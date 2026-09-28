import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../admin/views/dashboard/admin_shell.dart';
import '../../logic/resource_query.dart';
import '../resources/resources_screen.dart';
import '../../services/chatbot/ai_assistant_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/avatar_view.dart';
import '../../services/xp_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/levels.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../events/explore_tab.dart';
import 'home_tab.dart';
import '../explore/lore_tab.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/profile_tab.dart';
import '../shop/shop_tab.dart';

class FanHomeScreen extends StatefulWidget {
  const FanHomeScreen({super.key});

  static const int loreTab = 1;
  static const int eventsTab = 2;
  static const int shopTab = 3;

  static final ValueNotifier<({int index, WidgetBuilder? backTo})?>
      _tabRequest = ValueNotifier(null);

  static void openTab(BuildContext context, int index,
      {WidgetBuilder? backTo}) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    _tabRequest.value = (index: index, backTo: backTo);
  }

  @override
  State<FanHomeScreen> createState() => _FanHomeScreenState();
}

void showFanAssistant(BuildContext context) {
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

class _FanHomeScreenState extends State<FanHomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    FanHomeScreen._tabRequest.addListener(_onTabRequest);
    XpService.instance.levelUps.addListener(_onLevelUp);
  }

  @override
  void dispose() {
    FanHomeScreen._tabRequest.removeListener(_onTabRequest);
    XpService.instance.levelUps.removeListener(_onLevelUp);
    _glowController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAIAssistant() => showFanAssistant(context);

  void _openResourcesSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResourcesScreen(initialFilter: ResourceFilter(query: q)),
      ),
    );
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  WidgetBuilder? _backTo;

  void _onTabRequest() {
    final request = FanHomeScreen._tabRequest.value;
    if (request == null || !mounted) return;
    FanHomeScreen._tabRequest.value = null;
    setState(() {
      _currentIndex = request.index;
      _backTo = request.backTo;
    });
  }

  PreferredSizeWidget _buildAppBar() {
    final double appBarHeight = _currentIndex == 0 ? 130 : 75;
    // Narrow phones (≈360dp): tighten the logo, gaps and buttons so the
    // guest LOG IN + JOIN buttons fit instead of overflowing off-screen.
    final bool compact = MediaQuery.sizeOf(context).width < 420;
    return PreferredSize(
      preferredSize: Size.fromHeight(appBarHeight),
      child: Stack(
        children: [
          // ── 1. Animated Ambient Glow ────────────────────────────────
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -40,
                    left: 20 + (20 * _glowController.value),
                    child: Container(
                      width: 150,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accent.withValues(alpha: 0.15 * _glowController.value),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -40,
                    right: 20 + (20 * (1 - _glowController.value)),
                    child: Container(
                      width: 150,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.cyan.withValues(alpha: 0.15 * (1 - _glowController.value)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.cyan.withValues(alpha: 0.2),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── 2. The Glass Header Surface ────────────────────────────
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0E15).withValues(alpha: 0.7),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Logo Row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            // Premium Sharp Logo
                            Container(
                              width: compact ? 32 : 36,
                              height: compact ? 32 : 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  colors: [AppTheme.accent, AppTheme.cyan],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accent.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: -2,
                                  ),
                                  const BoxShadow(
                                    color: Colors.white24,
                                    offset: Offset(1, 1),
                                    blurRadius: 1,
                                    // inset: true,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'F',
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    shadows: [
                                      const Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: compact ? 10 : 14),
                            // Branding: takes the free space and scales down
                            // (never overflows) when the buttons need room.
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Colors.white, AppTheme.cyan, AppTheme.accent],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ).createShader(bounds),
                                  child: Text(
                                    'FANDOM VERSE',
                                    style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    'POCKET EDITION',
                                    style: GoogleFonts.orbitron(
                                      color: AppTheme.textMuted,
                                      fontSize: 7.5,
                                      letterSpacing: 2.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Auth/User Controls
                            ValueListenableBuilder<UserData?>(
                              valueListenable: AuthService.instance.userNotifier,
                              builder: (context, user, _) {
                                if (user == null) {
                                  return Row(
                                    children: [
                                      _buildPremiumButton(
                                        label: 'LOG IN',
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        ),
                                        isPrimary: false,
                                        compact: compact,
                                      ),
                                      SizedBox(width: compact ? 6 : 10),
                                      _buildPremiumButton(
                                        label: 'JOIN',
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                                        ),
                                        isPrimary: true,
                                        compact: compact,
                                      ),
                                    ],
                                  );
                                }
                                final isAdmin = user.role == 'admin';
                                return Row(
                                  children: [
                                    _buildUserBadge(isAdmin ? 'ADMIN' : 'FAN', isAdmin, user),
                                    const SizedBox(width: 6),
                                    _buildLevelChip(user.xp),
                                    if (isAdmin) ...[
                                      const SizedBox(width: 10),
                                      _buildGlossyIconButton(
                                        icon: Icons.admin_panel_settings_rounded,
                                        color: AppTheme.orange,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const AdminShell()),
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
                      // Search Bar (Home Only)
                      if (_currentIndex == 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: _buildPremiumSearchBar(),
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

  Widget _buildPremiumButton({
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [AppTheme.accent, AppTheme.cyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary ? null : Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: isPrimary ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelChip(int xp) => Tooltip(
        message: 'Level ${levelFor(xp)}: ${levelName(levelFor(xp))}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
          ),
          child: Text(
            'Lv ${levelFor(xp)}',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );

  void _onLevelUp() {
    final level = XpService.instance.levelUps.value;
    if (level == null || !mounted) return;
    XpService.instance.levelUps.value = null;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.emoji_events_rounded, color: AppTheme.orange, size: 40),
        title: Text('Level up!',
            textAlign: TextAlign.center,
            style: AppTheme.orbitron(size: 16, weight: FontWeight.w800)),
        content: Text('You\'re now Level $level: ${levelName(level)}.',
            textAlign: TextAlign.center,
            style: AppTheme.inter(size: 14, color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Nice!', style: AppTheme.inter(size: 13, color: AppTheme.cyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBadge(String label, bool isAdmin, UserData user) {
    final color = isAdmin ? AppTheme.orange : AppTheme.cyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarView.user(user, radius: 9),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlossyIconButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildPremiumSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.02),
            offset: const Offset(0, -1),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        textInputAction: TextInputAction.search,
        onSubmitted: _openResourcesSearch,
        style: AppTheme.inter(color: Colors.white, size: 14),
        decoration: InputDecoration(
          hintText: 'Search news, videos, podcasts, fandoms',
          hintStyle: AppTheme.inter(color: AppTheme.textMuted.withValues(alpha: 0.6), size: 14),
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.cyan.withValues(alpha: 0.7), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserData?>(
      valueListenable: AuthService.instance.userNotifier,
      builder: (context, user, _) {
        if (user != null && !user.hasOnboarded) {
          return OnboardingScreen(user: user);
        }
        return PopScope(
          canPop: _backTo == null,
          onPopInvokedWithResult: (didPop, _) {
            final backTo = _backTo;
            if (didPop || backTo == null) return;
            setState(() => _backTo = null);
            Navigator.push(context, MaterialPageRoute(builder: backTo));
          },
          child: _buildTabs(context),
        );
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
      // Content starts BELOW the header. With extendBodyBehindAppBar: true
      // the tabs started at the top of the screen, under the 130px header,
      // and the Home slider / other tabs' titles were hidden behind it.
      backgroundColor: AppTheme.bg,
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.cyan, AppTheme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cyan.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
          onDestinationSelected: (index) => setState(() {
            _currentIndex = index;
            _backTo = null;
          }),
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
      XpService.instance.award(XpAction.aiQuestion);
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
