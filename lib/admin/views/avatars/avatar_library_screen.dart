import 'package:flutter/material.dart';
import '../../../models/app_category.dart';
import '../../../models/avatar_library_item.dart';
import '../../../services/avatar_library_service.dart';
import '../../../services/category_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/image_upload_field.dart';

class AvatarLibraryScreen extends StatefulWidget {
  const AvatarLibraryScreen({super.key});

  @override
  State<AvatarLibraryScreen> createState() => _AvatarLibraryScreenState();
}

class _AvatarLibraryScreenState extends State<AvatarLibraryScreen> {
  late final Stream<List<AvatarLibraryItem>> _items = AvatarLibraryService.instance.watchAll();
  late final Stream<List<AppCategory>> _categories = CategoryService.instance.watchCategories();

  Future<void> _openForm(List<AppCategory> cats, [AvatarLibraryItem? existing]) => showDialog<void>(
        context: context,
        builder: (_) => _AvatarFormDialog(categories: cats, existing: existing),
      );

  Future<void> _setActive(AvatarLibraryItem item, bool active) async {
    try {
      await AvatarLibraryService.instance.update(item.id, isActive: active);
    } catch (e) {
      debugPrint('Avatar update failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not update. Check your connection.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCategory>>(
      stream: _categories,
      builder: (context, catSnap) {
        final cats = catSnap.data ?? const <AppCategory>[];
        final names = {for (final c in cats) c.key: c.name};
        return StreamBuilder<List<AvatarLibraryItem>>(
          stream: _items,
          builder: (context, snap) {
            if (snap.hasError) {
              debugPrint('Avatar library load error: ${snap.error}');
              return Center(
                child: Text('Could not load avatars. Check your connection.',
                    style: AppTheme.inter(size: 12, color: Colors.redAccent)),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.cyan));
            }
            final items = snap.data!;
            final groups = <String, List<AvatarLibraryItem>>{};
            for (final a in items) {
              final key = names.containsKey(a.categoryId) ? a.categoryId : AvatarLibraryItem.general;
              groups.putIfAbsent(key, () => []).add(a);
            }
            final order = [
              if (groups.containsKey(AvatarLibraryItem.general)) AvatarLibraryItem.general,
              for (final c in cats)
                if (groups.containsKey(c.key)) c.key,
            ];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(children: [
                    Expanded(child: Text('Avatars', style: AppTheme.orbitron(size: 12, color: AppTheme.cyan))),
                    ElevatedButton.icon(
                      onPressed: () => _openForm(cats),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add, size: 15),
                      label: Text('ADD', style: AppTheme.orbitron(size: 9, color: Colors.black)),
                    ),
                  ]),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text('No library avatars yet. Tap ADD to upload artwork.',
                              textAlign: TextAlign.center,
                              style: AppTheme.inter(size: 13, color: Colors.grey)),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            for (final key in order) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 8),
                                child: Text(
                                  (key == AvatarLibraryItem.general ? 'General' : names[key]!).toUpperCase(),
                                  style: AppTheme.orbitron(size: 10, color: Colors.grey, weight: FontWeight.w700),
                                ),
                              ),
                              GridView.extent(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                maxCrossAxisExtent: 120,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.78,
                                children: [for (final a in groups[key]!) _tile(cats, a)],
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _tile(List<AppCategory> cats, AvatarLibraryItem a) => Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: a.isActive ? AppTheme.border : Colors.redAccent.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: Opacity(
                opacity: a.isActive ? 1 : 0.35,
                child: ClipOval(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(a.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                            color: AppTheme.bg,
                            child: const Icon(Icons.broken_image_outlined, color: Colors.grey))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(a.isActive ? 'Active' : 'Inactive',
                style: AppTheme.inter(size: 10, color: a.isActive ? AppTheme.cyan : Colors.redAccent)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.cyan),
                  onPressed: () => _openForm(cats, a),
                ),
                IconButton(
                  tooltip: a.isActive ? 'Deactivate' : 'Activate',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(a.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 16, color: a.isActive ? Colors.redAccent : AppTheme.cyan),
                  onPressed: () => _setActive(a, !a.isActive),
                ),
              ],
            ),
          ],
        ),
      );
}

class _AvatarFormDialog extends StatefulWidget {
  final List<AppCategory> categories;
  final AvatarLibraryItem? existing;
  const _AvatarFormDialog({required this.categories, this.existing});

  @override
  State<_AvatarFormDialog> createState() => _AvatarFormDialogState();
}

class _AvatarFormDialogState extends State<_AvatarFormDialog> {
  late String _imageUrl = widget.existing?.imageUrl ?? '';
  late String _categoryId;
  late bool _active = widget.existing?.isActive ?? true;
  bool _saving = false;
  bool _imageBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // A deleted/unknown category would leave the dropdown showing General
    // while saving the stale key; normalize so what's shown is what's saved.
    final id = widget.existing?.categoryId ?? AvatarLibraryItem.general;
    _categoryId = id == AvatarLibraryItem.general ||
            widget.categories.any((c) => c.key == id)
        ? id
        : AvatarLibraryItem.general;
  }

  Future<void> _save() async {
    if (_imageBusy) {
      setState(() => _error = 'Wait for the image to finish uploading.');
      return;
    }
    if (_imageUrl.isEmpty) {
      setState(() => _error = 'Upload an image first.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = widget.existing;
      if (existing == null) {
        await AvatarLibraryService.instance.add(_imageUrl, _categoryId, isActive: _active);
      } else {
        await AvatarLibraryService.instance.update(existing.id, categoryId: _categoryId, isActive: _active);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Avatar save failed: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit avatar' : 'New avatar', style: AppTheme.orbitron(size: 13)),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEdit)
                Center(
                  child: ClipOval(
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: Image.network(_imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                )
              else
                ImageUploadField(
                  onUploaded: (url) => setState(() => _imageUrl = url),
                  onBusyChanged: (busy) {
                    if (mounted) setState(() => _imageBusy = busy);
                  },
                  accentColor: AppTheme.cyan,
                  isCircular: true,
                  circleRadius: 48,
                ),
              if (_imageBusy)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Center(
                    child: Text('Wait for the image to finish uploading',
                        style: AppTheme.inter(size: 11, color: Colors.grey)),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Category', style: AppTheme.inter(size: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                dropdownColor: AppTheme.card,
                isExpanded: true,
                style: AppTheme.inter(size: 13, color: Colors.white),
                decoration: const InputDecoration(isDense: true),
                items: [
                  const DropdownMenuItem(value: AvatarLibraryItem.general, child: Text('General')),
                  for (final c in widget.categories)
                    DropdownMenuItem(value: c.key, child: Text(c.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _categoryId = v ?? AvatarLibraryItem.general),
              ),
              ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  activeThumbColor: AppTheme.cyan,
                  onChanged: (v) => setState(() => _active = v),
                  title: Text('Active', style: AppTheme.inter(size: 13)),
                  subtitle: Text('Inactive avatars are hidden from the picker. Fans already using one keep it.',
                      style: AppTheme.inter(size: 11, color: Colors.grey)),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: AppTheme.inter(size: 12, color: Colors.redAccent)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text('CANCEL', style: AppTheme.inter(size: 12, color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _saving || _imageBusy ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cyan),
          child: Text('SAVE', style: AppTheme.inter(size: 12, color: Colors.black, weight: FontWeight.w700)),
        ),
      ],
    );
  }
}
