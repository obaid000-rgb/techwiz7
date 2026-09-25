import 'package:flutter/material.dart';
import '../models/app_category.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';

/// Shared category-picker widget used everywhere a category must be selected:
/// post/merch/event forms.
class CategoryPickerField extends StatefulWidget {
  final String? value;
  final void Function(String?) onChanged;
  final Color accentColor;

  const CategoryPickerField({
    super.key,
    this.value,
    required this.onChanged,
    this.accentColor = AppTheme.cyan,
  });

  @override
  State<CategoryPickerField> createState() => _CategoryPickerFieldState();
}

class _CategoryPickerFieldState extends State<CategoryPickerField> {
  late Future<List<AppCategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = CategoryService.instance.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppCategory>>(
      future: _future,
      builder: (context, snap) {
        final allCats = snap.data ?? [];

        AppCategory? selected;
        if (widget.value != null) {
          final matches = allCats.where((c) => c.key == widget.value);
          if (matches.isNotEmpty) selected = matches.first;
        }
        final displayName = selected?.name;

        final activeCats = allCats.where((c) => c.isActive).toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        final isLoading = snap.connectionState == ConnectionState.waiting;

        return GestureDetector(
          onTap: isLoading ? null : () => _openPicker(context, activeCats),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: isLoading
                      ? Text('Loading…',
                          style: AppTheme.inter(
                              size: 13, color: Colors.grey))
                      : Text(
                          displayName ?? 'Select category',
                          style: AppTheme.inter(
                            size: 13,
                            color: displayName != null
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppTheme.border),
                  )
                else
                  Icon(Icons.expand_more,
                      color: widget.accentColor, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPicker(BuildContext context, List<AppCategory> activeCats) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Category', style: AppTheme.orbitron(size: 11)),
                  TextButton(
                    onPressed: () {
                      widget.onChanged(null);
                      Navigator.pop(ctx);
                    },
                    child: Text('Clear',
                        style:
                            AppTheme.inter(size: 12, color: Colors.grey)),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.only(bottom: 24),
                children: activeCats
                    .map((c) => ListTile(
                          dense: true,
                          leading: _catThumb(c, size: 32),
                          title: Text(c.name,
                              style: AppTheme.inter(
                                  size: 13, color: Colors.white)),
                          trailing: widget.value == c.key
                              ? Icon(Icons.check,
                                  color: widget.accentColor, size: 18)
                              : null,
                          onTap: () {
                            widget.onChanged(c.key);
                            Navigator.pop(ctx);
                          },
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _catThumb(AppCategory cat, {double size = 32}) {
  if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        cat.imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => _thumbPlaceholder(size),
      ),
    );
  }
  return _thumbPlaceholder(size);
}

Widget _thumbPlaceholder(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.category_outlined,
          color: AppTheme.accent, size: size * 0.5),
    );
