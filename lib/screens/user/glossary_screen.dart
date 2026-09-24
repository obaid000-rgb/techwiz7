import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fandom Glossary'), backgroundColor: AppTheme.card),
      body: const Center(
        child: Text('Terms & Definitions Directory', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}