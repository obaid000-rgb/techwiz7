import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'profile_tab.dart';

class FanHomeScreen extends StatefulWidget {
  const FanHomeScreen({super.key});

  @override
  State<FanHomeScreen> createState() => _FanHomeScreenState();
}

class _FanHomeScreenState extends State<FanHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    _ComingSoonTab(title: 'Explore', icon: Icons.explore_outlined, phase: 'Phase 3'),
    _ComingSoonTab(title: 'Events', icon: Icons.event_outlined, phase: 'Phase 4'),
    _ComingSoonTab(title: 'Store', icon: Icons.storefront_outlined, phase: 'Phase 5'),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Store'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
class _ComingSoonTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final String phase;

  const _ComingSoonTab({required this.title, required this.icon, required this.phase});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Coming in $phase', style: const TextStyle(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}