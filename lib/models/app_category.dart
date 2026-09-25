import 'package:flutter/material.dart';

class AppCategory {
  final String id;
  final String key;
  final String name;
  final String iconName;
  final int order;

  const AppCategory({
    required this.id,
    required this.key,
    required this.name,
    required this.iconName,
    this.order = 0,
  });

  IconData get icon => iconMap[iconName] ?? Icons.category_outlined;

  static const Map<String, IconData> iconMap = {
    'tv': Icons.tv,
    'sports_esports': Icons.sports_esports,
    'rocket_launch': Icons.rocket_launch,
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'book': Icons.book_outlined,
    'sports': Icons.sports,
    'videogame_asset': Icons.videogame_asset,
    'auto_awesome': Icons.auto_awesome,
    'favorite': Icons.favorite_border,
    'star': Icons.star_border,
    'category': Icons.category_outlined,
  };

  factory AppCategory.fromMap(Map<String, dynamic> map, String docId) =>
      AppCategory(
        id: docId,
        key: map['key'] ?? docId,
        name: map['name'] ?? '',
        iconName: map['iconName'] ?? 'category',
        order: (map['order'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'key': key,
        'name': name,
        'iconName': iconName,
        'order': order,
      };

  AppCategory copyWith({
    String? key,
    String? name,
    String? iconName,
    int? order,
  }) =>
      AppCategory(
        id: id,
        key: key ?? this.key,
        name: name ?? this.name,
        iconName: iconName ?? this.iconName,
        order: order ?? this.order,
      );
}
