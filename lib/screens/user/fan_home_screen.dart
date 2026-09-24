import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../explore_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';

class FanHomeScreen extends StatefulWidget {
  const FanHomeScreen({super.key});

  @override
  State<FanHomeScreen> createState() => _FanHomeScreenState();
}

class _FanHomeScreenState extends State<FanHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(), // Feed
    const Center(child: Text('Lore Screen', style: TextStyle(color: Colors.white))), // Lore
    const ExploreTab(), // Events
    const Center(child: Text('Shop Screen', style: TextStyle(color: Colors.white))), // Shop
    const ProfileTab(), // Saved / Profile
  ];

  void _openAIAssistant() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.cyan,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy, color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fandom AI Assistant',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16)),
                      Text('Ask anything about Lore or Events',
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                style: const TextStyle(color: Colors.white),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppTheme.cyan, borderRadius: BorderRadius.circular(8)),
              child: const Text('F',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            const Text('FANDOM VERSE',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),

      // Floating AI Bot Button with Notification Badge
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
              decoration: const BoxDecoration(
                color: AppTheme.orange,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: const Text(
                '1',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),

      // 5 Bottom Navigation Bar Items matching screenshot
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.bg,
        selectedItemColor: AppTheme.cyan,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
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
