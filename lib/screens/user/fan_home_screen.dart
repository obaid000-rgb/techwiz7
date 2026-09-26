import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../admin/views/admin_shell.dart';
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
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fandom AI Assistant', style: AppTheme.orbitron(size: 14, weight: FontWeight.w700)),
                    Text('Ask anything about Lore or Events', style: AppTheme.inter(size: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              style: AppTheme.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Explain Breathing Styles in Demon Slayer...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.cyan),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI is analyzing your request...')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, UserData user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // avatar + name + email
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.cyan]),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: user.avatarUrl.isNotEmpty
                        ? NetworkImage(user.avatarUrl) : null,
                    backgroundColor: AppTheme.bg,
                    child: user.avatarUrl.isEmpty
                        ? Text(user.name[0].toUpperCase(),
                            style: AppTheme.orbitron(size: 22, weight: FontWeight.w900))
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: AppTheme.orbitron(size: 15, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(user.email,
                          style: AppTheme.inter(size: 11, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                            ),
                            child: Text(user.rank,
                                style: AppTheme.orbitron(
                                    size: 9, color: AppTheme.accent, weight: FontWeight.w700)),
                          ),
                          if (user.badge.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.cyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
                              ),
                              child: Text(user.badge,
                                  style: AppTheme.orbitron(
                                      size: 9, color: AppTheme.cyan, weight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _sheetStat(Icons.bookmark_outline, '${user.bookmarkedPostIds.length}', 'Liked', AppTheme.cyan),
                  Container(width: 1, height: 32, color: AppTheme.border),
                  _sheetStat(Icons.confirmation_number_outlined, '${user.savedEvents}', 'Events', AppTheme.pink),
                  Container(width: 1, height: 32, color: AppTheme.border),
                  _sheetStat(Icons.emoji_events_outlined, user.rank, 'Rank', AppTheme.orange),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  AuthService.instance.signOut();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 16),
                label: Text('LOG OUT',
                    style: AppTheme.orbitron(
                        size: 10, color: Colors.redAccent, weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.orbitron(size: 12, color: color, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.inter(size: 9, color: Colors.grey)),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(116),
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
                        // signed-in shows FAN badge + avatar
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
                            // Signed-in: role badge + optional admin button + avatar
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
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => _showProfileSheet(context, user),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                              colors: [AppTheme.accent, AppTheme.cyan]),
                                        ),
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundImage: user.avatarUrl.isNotEmpty
                                              ? NetworkImage(user.avatarUrl)
                                              : null,
                                          backgroundColor: AppTheme.card,
                                          child: user.avatarUrl.isEmpty
                                              ? Text(user.name[0].toUpperCase(),
                                                  style: AppTheme.orbitron(
                                                      size: 12, weight: FontWeight.w900))
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 1,
                                        right: 1,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF22C55E),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppTheme.bg, width: 1.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // ── Search bar ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        style: AppTheme.inter(color: Colors.white, size: 13),
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search Lore, Fandoms, Events, Merch...',
                          hintStyle: AppTheme.inter(color: Colors.grey, size: 12),
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
      floatingActionButton: Stack(
        alignment: Alignment.center,
        children: [
          FloatingActionButton(
            onPressed: _openAIAssistant,
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
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppTheme.orange, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: const Text('1',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.bg,
        selectedItemColor: AppTheme.cyan,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 9,
        unselectedFontSize: 9,
        selectedLabelStyle: GoogleFonts.orbitron(fontSize: 9, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.orbitron(fontSize: 9),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Lore'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), label: 'Saved'),
        ],
      ),
    );
  }
}
