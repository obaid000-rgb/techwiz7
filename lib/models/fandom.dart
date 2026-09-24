import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Fandom {
  final String id;
  final String name;
  final String category;
  final String description;
  final bool trending;

  const Fandom({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.trending,
  });

  factory Fandom.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Fandom(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? 'Untitled Fandom',
      category: (data['category'] as String?)?.trim() ?? 'General',
      description: (data['description'] as String?)?.trim() ?? '',
      trending: data['trending'] as bool? ?? false,
    );
  }

  static IconData iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'anime':
        return Icons.movie_filter_outlined;
      case 'gaming':
        return Icons.sports_esports_outlined;
      case 'comics':
        return Icons.auto_stories_outlined;
      case 'movies & tv':
        return Icons.theaters_outlined;
      case 'music':
        return Icons.mic_external_on_outlined;
      case 'sci-fi':
        return Icons.rocket_launch_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  static Color colorFor(String category) {
    switch (category.toLowerCase()) {
      case 'anime':
        return const Color(0xFFEF4444);
      case 'gaming':
        return const Color(0xFF3B82F6);
      case 'comics':
        return const Color(0xFFF59E0B);
      case 'movies & tv':
        return const Color(0xFF10B981);
      case 'music':
        return const Color(0xFFEC4899);
      case 'sci-fi':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF8B5CF6);
    }
  }
}