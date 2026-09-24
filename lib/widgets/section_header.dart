import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? trailingText;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1.1,
                color: Colors.white,
              ),
            ),
          ],
        ),
        if (trailingText != null)
          Text(
            trailingText!,
            style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11),
          ),
      ],
    );
  }
}