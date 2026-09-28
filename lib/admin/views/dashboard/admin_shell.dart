import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_logo.dart';
import 'admin_dashboard.dart';
import '../avatars/avatar_library_screen.dart';
import '../backup/backup_screen.dart';
import '../faqs/faq_management_screen.dart';
import '../inquiries/inquiry_management_screen.dart';
import '../team/team_management_screen.dart';
import '../categories/category_management_screen.dart';
import '../content/content_moderation_screen.dart';
import '../creators/creator_management_screen.dart';
import '../fandoms/fandom_management_screen.dart';
import '../glossary/glossary_management_screen.dart';
import '../onboarding_slides/onboarding_slide_management_screen.dart';
import '../orders/order_management_screen.dart';
import '../users/user_management_screen.dart';

// ── Nav-item config ────────────────────────────────────────────────────────────
// Add a new sidebar entry by appending one _NavItem here — nothing else changes.

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;
  final Widget child;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.child,
  });
}

// ── Shell ──────────────────────────────────────────────────────────────────────

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  /// Switches the shell to the section with this sidebar [label] — the same
  /// index the rail/drawer sets. Used by dashboard cards.
  static void openSection(BuildContext context, String label) =>
      context.findAncestorStateOfType<_AdminShellState>()?._selectByLabel(label);

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  // BACK-NAVIGATION — read before adding a new section or dashboard link.
  // The whole admin panel is ONE route: sections are swapped inside this
  // shell's IndexedStack (sidebar, drawer and dashboard cards all call
  // _go), not pushed as routes. Without this history, Android back / the
  // browser back button popped the entire AdminShell and dumped the admin
  // out of the panel instead of returning to Dashboard. So:
  //  • switch sections ONLY via _go (or AdminShell.openSection) — never
  //    setState(_selectedIndex) directly, or back will skip that section;
  //  • real sub-screens (forms, order detail) are still pushed with
  //    Navigator.push, which stacks on top and pops back here normally.
  // Back walks this history, ends at Dashboard, and only then leaves admin.
  final List<int> _history = [];

  void _go(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      if (index == 0) {
        _history.clear(); // Dashboard is the root: nothing behind it
      } else {
        _history.add(_selectedIndex);
      }
      _selectedIndex = index;
    });
  }

  void _back() => setState(() {
        _selectedIndex = _history.isNotEmpty ? _history.removeLast() : 0;
      });

  void _selectByLabel(String label) {
    final i = _navItems.indexWhere((e) => e.label == label);
    if (i >= 0) _go(i);
  }

  static final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
      color: AppTheme.accent,
      child: const AdminDashboard(),
    ),
    _NavItem(
      icon: Icons.article_outlined,
      label: 'Content',
      color: AppTheme.cyan,
      child: const ContentModerationScreen(),
    ),
    _NavItem(
      icon: Icons.event_outlined,
      label: 'Events',
      color: AppTheme.pink,
      child: const EventsSection(),
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      label: 'Orders',
      color: AppTheme.orange,
      child: const OrderManagementScreen(),
    ),
    _NavItem(
      icon: Icons.people_outline,
      label: 'Users',
      color: AppTheme.accent,
      child: const UserManagementScreen(),
    ),
    _NavItem(
      icon: Icons.category_outlined,
      label: 'Categories',
      color: AppTheme.orange,
      child: const CategoryManagementScreen(),
    ),
    _NavItem(
      icon: Icons.hub_outlined,
      label: 'Fandoms',
      color: AppTheme.pink,
      child: const FandomManagementScreen(),
    ),
    _NavItem(
      icon: Icons.record_voice_over_outlined,
      label: 'Creators',
      color: AppTheme.orange,
      child: const CreatorManagementScreen(),
    ),
    _NavItem(
      icon: Icons.menu_book_outlined,
      label: 'Glossary',
      color: AppTheme.cyan,
      child: const GlossaryManagementScreen(),
    ),
    _NavItem(
      icon: Icons.slideshow_outlined,
      label: 'Onboarding',
      color: AppTheme.pink,
      child: const OnboardingSlideManagementScreen(),
    ),
    _NavItem(
      icon: Icons.face_retouching_natural,
      label: 'Avatars',
      color: AppTheme.cyan,
      child: const AvatarLibraryScreen(),
    ),
    _NavItem(
      icon: Icons.mail_outline,
      label: 'Inquiries',
      color: AppTheme.pink,
      child: const InquiryManagementScreen(),
    ),
    _NavItem(
      icon: Icons.groups_2_outlined,
      label: 'About Us Team',
      color: AppTheme.accent,
      child: const TeamManagementScreen(),
    ),
    _NavItem(
      icon: Icons.quiz_outlined,
      label: 'FAQs',
      color: AppTheme.cyan,
      child: const FaqManagementScreen(),
    ),
    _NavItem(
      icon: Icons.backup_outlined,
      label: 'Backup',
      color: AppTheme.orange,
      child: const BackupScreen(),
    ),
  ];

  static final List<Widget> _children =
      _navItems.map((e) => e.child).toList();

  static Widget _brandMark({double size = 32}) => AppLogo(size: size);

  AppBar _appBar(BuildContext context, {bool showMenuAction = false}) {
    return AppBar(
      backgroundColor: AppTheme.card,
      elevation: 0,
      leading: showMenuAction
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                tooltip: 'Open navigation',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _brandMark(),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ADMIN PANEL',
                  style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              Text('FANDOM VERSE',
                  style: GoogleFonts.orbitron(
                      color: AppTheme.orange,
                      fontSize: 7,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          tooltip: 'Back to Fan View',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.orange.withValues(alpha: 0.05),
                AppTheme.orange.withValues(alpha: 0.4),
                AppTheme.orange.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only leave the admin panel from Dashboard; any other section goes
    // back through _history (see the note on _history above).
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _layout(),
    );
  }

  Widget _layout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          // ── Tablet / wide: persistent side rail ───────────────────────────
          return Scaffold(
            backgroundColor: AppTheme.bg,
            appBar: _appBar(context),
            body: Row(
              children: [
                _SideRail(
                  items: _navItems,
                  selectedIndex: _selectedIndex,
                  onTap: _go,
                ),
                Container(width: 1, color: AppTheme.border),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _children,
                  ),
                ),
              ],
            ),
          );
        } else {
          // ── Phone: drawer ─────────────────────────────────────────────────
          return Scaffold(
            backgroundColor: AppTheme.bg,
            appBar: _appBar(context, showMenuAction: true),
            drawer: _NavDrawer(
              items: _navItems,
              selectedIndex: _selectedIndex,
              onTap: (i) {
                _go(i);
                Navigator.pop(context); // closes the drawer only
              },
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: _children,
            ),
          );
        }
      },
    );
  }
}

// ── Side rail (tablet) ─────────────────────────────────────────────────────────

class _SideRail extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _SideRail({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: AppTheme.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Text('MANAGE',
                style: GoogleFonts.orbitron(
                    color: Colors.white38, fontSize: 10, letterSpacing: 1.8)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  child: Material(
                    color: isSelected
                        ? item.color.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onTap(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: item.color.withValues(alpha: 0.4))
                              : Border.all(color: Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? item.color.withValues(alpha: 0.18)
                                    : AppTheme.bg,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: Icon(item.icon,
                                  color: isSelected ? item.color : Colors.grey,
                                  size: 16),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                item.label,
                                style: AppTheme.inter(
                                    size: 12.5,
                                    color: isSelected ? Colors.white : Colors.grey,
                                    weight: isSelected ? FontWeight.w700 : FontWeight.w500),
                              ),
                            ),
                            if (isSelected) ...[
                              const Spacer(),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.white24, size: 13),
                const SizedBox(width: 6),
                Text('ADMIN ACCESS',
                    style: GoogleFonts.orbitron(
                        color: Colors.white24, fontSize: 8, letterSpacing: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer (phone) ─────────────────────────────────────────────────────────────

class _NavDrawer extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NavDrawer({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.card,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.orange, AppTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADMIN',
                        style: GoogleFonts.orbitron(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                    Text('FANDOM VERSE',
                        style: GoogleFonts.orbitron(
                            color: Colors.white.withValues(alpha: 0.85), fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: isSelected
                        ? item.color.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onTap(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? item.color.withValues(alpha: 0.18)
                                    : AppTheme.bg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Icon(item.icon,
                                  color: isSelected ? item.color : Colors.grey,
                                  size: 18),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              item.label,
                              style: AppTheme.inter(
                                  size: 13,
                                  color: isSelected ? Colors.white : Colors.grey,
                                  weight: isSelected ? FontWeight.w700 : FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
