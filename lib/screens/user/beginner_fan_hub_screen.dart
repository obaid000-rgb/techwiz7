import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BeginnerFanHubScreen extends StatelessWidget {
  const BeginnerFanHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beginner Fan Hub'), backgroundColor: AppTheme.card),
      body: const Center(
        child: Text('Starter Guides and Lore Roadmaps', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}