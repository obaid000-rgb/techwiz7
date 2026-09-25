import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg = Color(0xFF0D0E15);
  static const Color card = Color(0xFF151725);
  static const Color border = Color(0xFF262940);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color orange = Color(0xFFF97316);
  static const Color pink = Color(0xFFEC4899);

  static TextStyle orbitron({
    double size = 13,
    FontWeight weight = FontWeight.w700,
    Color color = Colors.white,
    double? letterSpacing,
  }) =>
      GoogleFonts.orbitron(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle inter({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bg,
      primaryColor: cyan,
      cardColor: card,
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: accent,
        surface: card,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cyan, width: 1.5),
        ),
      ),
    );
  }
}
