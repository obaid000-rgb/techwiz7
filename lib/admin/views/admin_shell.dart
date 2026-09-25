import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard.dart';
import 'category_management_screen.dart';
import 'content_moderation_screen.dart';
import 'user_management_screen.dart';

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

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

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
  ];

  static final List<Widget> _children =
      _navItems.map((e) => e.child).toList();

  AppBar _appBar(BuildContext context, {bool showMenuAction = false}) {
    return AppBar(
      backgroundColor: AppTheme.card,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: Colors.white, size: 18),
        tooltip: 'Back to Fan View',
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppTheme.orange.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: AppTheme.orange, size: 16),
          ),
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
      actions: showMenuAction
          ? [
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  tooltip: 'Open navigation',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ]
          : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child:
            Container(height: 1, color: AppTheme.orange.withValues(alpha: 0.3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  onTap: (i) => setState(() => _selectedIndex = i),
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
                setState(() => _selectedIndex = i);
                Navigator.pop(context);
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
      width: 176,
      color: AppTheme.card,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? item.color.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(
                        color: item.color.withValues(alpha: 0.4))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(item.icon,
                      color: isSelected ? item.color : Colors.grey,
                      size: 18),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      item.label,
                      style: AppTheme.orbitron(
                          size: 10,
                          color: isSelected ? item.color : Colors.grey,
                          weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.bg,
              border: Border(
                  bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.orange.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: AppTheme.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADMIN',
                        style: AppTheme.orbitron(
                            size: 14, weight: FontWeight.w800)),
                    Text('FANDOM VERSE',
                        style: AppTheme.orbitron(
                            size: 9, color: AppTheme.orange)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = i == selectedIndex;
                return ListTile(
                  leading: Icon(item.icon,
                      color: isSelected ? item.color : Colors.grey,
                      size: 20),
                  title: Text(
                    item.label,
                    style: AppTheme.orbitron(
                        size: 11,
                        color: isSelected ? item.color : Colors.grey,
                        weight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500),
                  ),
                  selected: isSelected,
                  selectedTileColor: item.color.withValues(alpha: 0.1),
                  onTap: () => onTap(i),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
