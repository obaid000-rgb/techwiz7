import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FandomVerseApp());
}

class FandomVerseApp extends StatelessWidget {
  const FandomVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fandom Verse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LandingScreen(),
    );
  }
}