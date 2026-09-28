import 'package:flutter/material.dart';
import '../models/avatar_preset.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AvatarView extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final String avatarPresetId;
  final double radius;

  const AvatarView({
    super.key,
    required this.name,
    this.avatarUrl = '',
    this.avatarPresetId = '',
    this.radius = 20,
  });

  AvatarView.user(UserData user, {super.key, this.radius = 20})
      : name = user.name,
        avatarUrl = user.avatarUrl,
        avatarPresetId = user.avatarPresetId;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts.last[0] : '';
    return (first + second).toUpperCase();
  }

  Widget _gradientCircle(List<Color> colors, Widget child) => Container(
        width: radius * 2,
        height: radius * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      );

  Widget _initialsView() => _gradientCircle(
        const [AppTheme.accent, AppTheme.cyan],
        Text(_initials,
            style: AppTheme.orbitron(size: radius * 0.62, weight: FontWeight.w900, color: Colors.white)),
      );

  @override
  Widget build(BuildContext context) {
    // Display order:
    //  1. a built-in avatar (avatarPresetId set and known) — drawn in code;
    //  2. otherwise the image at avatarUrl (uploaded photo or library art);
    //  3. otherwise the user's initials on a gradient (also the fallback
    //     while the image loads or if it fails).
    final preset = avatarPresetId.isEmpty ? null : presetById(avatarPresetId);
    if (preset != null) {
      return _gradientCircle(preset.colors, Icon(preset.icon, color: Colors.white, size: radius * 1.05));
    }
    if (avatarUrl.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image.network(
            avatarUrl,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => _initialsView(),
            loadingBuilder: (c, child, progress) => progress == null ? child : _initialsView(),
          ),
        ),
      );
    }
    return _initialsView();
  }
}
