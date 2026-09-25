import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
            Text(title, style: AppTheme.orbitron(size: 10, letterSpacing: 0.8)),
          ],
        ),
        if (trailingText != null)
          Text(trailingText!, style: AppTheme.inter(size: 11, color: AppTheme.cyan)),
      ],
    );
  }
}
