import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'content_moderation_screen.dart';
import 'user_management_screen.dart';
import 'category_management_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  static const _tabs = [
    ContentModerationScreen(),
    UserManagementScreen(),
    CategoryManagementScreen(),
  ];

  static const _labels = [
    'Moderation',
    'Users',
    'Categories',
  ];

  static const _icons = [
    Icons.content_paste_search,
    Icons.manage_accounts,
    Icons.category_outlined,
  ];

  static const _colors = [
    AppTheme.cyan,
    AppTheme.accent,
    AppTheme.orange,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
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
                border: Border.all(
                    color: AppTheme.orange.withValues(alpha: 0.5)),
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
                      letterSpacing: 1.2,
                    )),
                Text('FANDOM VERSE',
                    style: GoogleFonts.orbitron(
                      color: AppTheme.orange,
                      fontSize: 7,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1,
              color: AppTheme.orange.withValues(alpha: 0.3)),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppTheme.card,
        selectedItemColor: _colors[_currentIndex],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 9,
        unselectedFontSize: 9,
        selectedLabelStyle:
            GoogleFonts.orbitron(fontSize: 9, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.orbitron(fontSize: 9),
        items: List.generate(
          3,
          (i) => BottomNavigationBarItem(
            icon: Icon(_icons[i]),
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}
