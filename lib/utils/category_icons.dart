import 'package:flutter/material.dart';
import '../models/app_category.dart';

/// Picks a representative icon for a category from its key/name keywords.
/// Shared by onboarding and the Profile "My Fandoms" card.
IconData categoryIcon(AppCategory c) {
  final s = '${c.key} ${c.name}'.toLowerCase();
  if (s.contains('anime') || s.contains('amine') || s.contains('manga')) {
    return Icons.face_retouching_natural;
  }
  if (s.contains('music') || s.contains('song') || s.contains('k-pop')) return Icons.headphones_rounded;
  if (s.contains('gam') || s.contains('esport')) return Icons.sports_esports_rounded;
  if (s.contains('comic') || s.contains('car')) return Icons.menu_book_rounded;
  if (s.contains('sci') || s.contains('space') || s.contains('star')) return Icons.public_rounded;
  if (s.contains('movie') || s.contains('film') || s.contains('tv') || s.contains('series')) {
    return Icons.movie_filter_rounded;
  }
  if (s.contains('book') || s.contains('novel') || s.contains('fantasy')) return Icons.auto_stories_rounded;
  if (s.contains('sport')) return Icons.sports_soccer_rounded;
  return Icons.auto_awesome_rounded;
}
