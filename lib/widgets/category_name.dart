import 'package:flutter/material.dart';
import '../models/app_category.dart';
import '../services/category_service.dart';

/// Turns a raw category key into something readable when the category
/// document can't be found: underscores become spaces, all caps.
String prettifyCategoryKey(String key) =>
    key.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

Future<List<AppCategory>>? _categoriesFuture;

/// Categories fetched once per app run and shared by every label; a failed
/// fetch is dropped so the next label retries.
Future<List<AppCategory>> _categories() {
  return _categoriesFuture ??= CategoryService.instance.fetchCategories().catchError((Object e) {
    _categoriesFuture = null;
    return <AppCategory>[];
  });
}

/// Builds [builder] with the display name (upper-cased) for category [categoryKey].
/// Falls back to the prettified key — never the raw key.
class CategoryName extends StatelessWidget {
  final String categoryKey;
  final Widget Function(BuildContext context, String label) builder;

  const CategoryName({super.key, required this.categoryKey, required this.builder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppCategory>>(
      future: _categories(),
      builder: (context, snap) {
        final matches = (snap.data ?? const <AppCategory>[]).where((c) => c.key == categoryKey);
        final label = matches.isEmpty ? prettifyCategoryKey(categoryKey) : matches.first.name.toUpperCase();
        return builder(context, label);
      },
    );
  }
}
