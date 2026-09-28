import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AvatarPreset {
  final String id;
  final String label;
  final IconData icon;
  final List<Color> colors;
  final String group;

  const AvatarPreset(this.id, this.label, this.icon, this.colors, this.group);
}

const List<AvatarPreset> kAvatarPresets = [
  AvatarPreset('controller', 'Controller', Icons.sports_esports_rounded, [AppTheme.cyan, AppTheme.accent], 'gaming'),
  AvatarPreset('trophy', 'Trophy', Icons.emoji_events_rounded, [AppTheme.orange, AppTheme.pink], 'gaming'),
  AvatarPreset('shield', 'Shield', Icons.shield_rounded, [AppTheme.accent, AppTheme.pink], 'anime'),
  AvatarPreset('sparkle', 'Sparkle', Icons.auto_awesome_rounded, [AppTheme.pink, AppTheme.accent], 'anime'),
  AvatarPreset('headphones', 'Headphones', Icons.headphones_rounded, [AppTheme.pink, AppTheme.orange], 'music'),
  AvatarPreset('mic', 'Mic', Icons.mic_rounded, [AppTheme.accent, AppTheme.cyan], 'music'),
  AvatarPreset('film', 'Film Reel', Icons.movie_rounded, [AppTheme.orange, AppTheme.accent], 'movies'),
  AvatarPreset('rocket', 'Rocket', Icons.rocket_launch_rounded, [AppTheme.cyan, AppTheme.pink], 'movies'),
  AvatarPreset('bolt', 'Bolt', Icons.bolt_rounded, [AppTheme.orange, AppTheme.cyan], 'comics'),
  AvatarPreset('book', 'Comic Book', Icons.menu_book_rounded, [AppTheme.cyan, AppTheme.orange], 'comics'),
  AvatarPreset('mask', 'Mask', Icons.theater_comedy_rounded, [AppTheme.pink, AppTheme.cyan], 'general'),
  AvatarPreset('star', 'Star', Icons.star_rounded, [AppTheme.accent, AppTheme.orange], 'general'),
  AvatarPreset('palette', 'Palette', Icons.palette_rounded, [AppTheme.cyan, AppTheme.accent], 'general'),
  AvatarPreset('moon', 'Moon', Icons.nightlight_round, [AppTheme.accent, AppTheme.cyan], 'general'),
];

const Map<String, List<String>> _groupWords = {
  'gaming': ['game', 'gaming', 'esport'],
  'anime': ['anime', 'manga'],
  'music': ['music', 'pop', 'song', 'band'],
  'movies': ['movie', 'film', 'cinema', 'tv', 'series', 'show'],
  'comics': ['comic', 'hero'],
};

AvatarPreset? presetById(String id) {
  for (final p in kAvatarPresets) {
    if (p.id == id) return p;
  }
  return null;
}

String? _groupFor(String categoryKey, String categoryName) {
  final text = '$categoryKey $categoryName'.toLowerCase();
  for (final e in _groupWords.entries) {
    if (e.value.any(text.contains)) return e.key;
  }
  return null;
}

List<AvatarPreset> presetsForCategory(String categoryKey, String categoryName) {
  final group = _groupFor(categoryKey, categoryName);
  return group == null ? const [] : kAvatarPresets.where((p) => p.group == group).toList();
}

List<AvatarPreset> presetsForGeneral(List<({String key, String name})> categories) {
  final matched = {for (final c in categories) ?_groupFor(c.key, c.name)};
  return kAvatarPresets
      .where((p) => p.group == 'general' || !matched.contains(p.group))
      .toList();
}
