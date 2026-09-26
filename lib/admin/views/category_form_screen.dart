import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../services/category_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_upload_field.dart';

class CategoryFormScreen extends StatefulWidget {
  final AppCategory? existing;
  const CategoryFormScreen({super.key, this.existing});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  late final TextEditingController _nameCtr;
  late final TextEditingController _keyCtr;
  late final TextEditingController _orderCtr;
  late final TextEditingController _descriptionCtr;
  String? _imageUrl;
  String _status = 'active';
  bool _isFeaturedInCarousel = false;
  bool _saving = false;
  String? _error;
  bool _keyEdited = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtr = TextEditingController(text: e?.name ?? '');
    _keyCtr = TextEditingController(text: e?.key ?? '');
    _orderCtr = TextEditingController(text: e?.order.toString() ?? '0');
    _descriptionCtr = TextEditingController(text: e?.description ?? '');
    _imageUrl = e?.imageUrl;
    _status = e?.status ?? 'active';
    _isFeaturedInCarousel = e?.isFeaturedInCarousel ?? false;
    if (e != null) _keyEdited = true;

    _nameCtr.addListener(() {
      if (!_keyEdited) {
        _keyCtr.text = _nameCtr.text
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      }
    });
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _keyCtr.dispose();
    _orderCtr.dispose();
    _descriptionCtr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtr.text.trim();
    final key = _keyCtr.text.trim();
    final order = int.tryParse(_orderCtr.text.trim()) ?? 0;

    if (name.isEmpty || key.isEmpty) {
      setState(() => _error = 'Name and key are required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final e = widget.existing;

      final duplicate = await CategoryService.instance
          .nameExists(name, excludeId: e?.id);
      if (duplicate) {
        if (mounted) {
          setState(() {
            _saving = false;
            _error = 'A category named "$name" already exists.';
          });
        }
        return;
      }

      if (e == null) {
        // New categories are appended to the end of the current order.
        final all = await CategoryService.instance.fetchCategories();
        final nextOrder = all.isEmpty
            ? 0
            : all.map((c) => c.order).reduce((a, b) => a > b ? a : b) + 1;
        await CategoryService.instance.addCategory(AppCategory(
          id: key,
          key: key,
          name: name,
          imageUrl: _imageUrl,
          status: _status,
          order: nextOrder,
          description: _descriptionCtr.text.trim(),
          isFeaturedInCarousel: _isFeaturedInCarousel,
        ));
      } else {
        await CategoryService.instance.updateCategory(
          e.copyWith(
            name: name,
            imageUrl: _imageUrl,
            status: _status,
            order: order,
            description: _descriptionCtr.text.trim(),
            isFeaturedInCarousel: _isFeaturedInCarousel,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Save failed: $e');
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
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        title: Text(
          isEdit ? 'Edit Category' : 'New Category',
          style: AppTheme.orbitron(size: 13),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.orange),
                  )
                : Text('SAVE',
                    style: AppTheme.orbitron(
                        size: 10, color: AppTheme.orange)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Text(_error!,
                    style: AppTheme.inter(
                        size: 12, color: Colors.redAccent)),
              ),

            // ── Image ────────────────────────────────────────────────
            Text('Category Image',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            ImageUploadField(
              initialUrl: _imageUrl,
              accentColor: AppTheme.orange,
              height: 160,
              onUploaded: (url) => setState(() => _imageUrl = url),
            ),
            const SizedBox(height: 16),

            _field('Name', _nameCtr, hint: 'Anime & Manga'),
            const SizedBox(height: 12),
            _field(
              'Key (unique slug)',
              _keyCtr,
              hint: 'anime_manga',
              readOnly: isEdit,
              onChanged: (_) => _keyEdited = true,
            ),
            const SizedBox(height: 12),
            _field(
              'Display Order',
              _orderCtr,
              hint: '0',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _field(
              'Description (optional)',
              _descriptionCtr,
              hint: 'Short tagline, e.g. "Worlds of anime & manga lore"',
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // ── Status ───────────────────────────────────────────────
            Text('Status',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButton<String>(
                value: _status,
                isExpanded: true,
                dropdownColor: AppTheme.card,
                underline: const SizedBox.shrink(),
                style: AppTheme.inter(size: 13, color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(
                      value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Featured in Carousel ───────────────────────────────────
            // Deliberately distinct styling from Status above: this only
            // controls Slider visibility, not whether the category works
            // anywhere else in the app.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.view_carousel_outlined,
                      color: AppTheme.cyan, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Featured in Carousel',
                            style: AppTheme.inter(
                                size: 13, color: Colors.white, weight: FontWeight.w600)),
                        Text('Shows this category in the carousel on Feed',
                            style: AppTheme.inter(size: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isFeaturedInCarousel,
                    activeThumbColor: AppTheme.cyan,
                    onChanged: (val) => setState(() => _isFeaturedInCarousel = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool readOnly = false,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.inter(size: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            readOnly: readOnly,
            onChanged: onChanged,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: AppTheme.inter(
                size: 13,
                color: readOnly ? Colors.grey : Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppTheme.bg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppTheme.orange)),
            ),
          ),
        ],
      );
}
