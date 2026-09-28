import 'package:flutter/material.dart';
import '../../../models/app_category.dart';
import '../../../models/fandom.dart';
import '../../../services/category_service.dart';
import '../../../services/fandom_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/image_upload_field.dart';
import '../../controllers/fandoms/fandom_controller.dart';
import '../../widgets/category_picker_field.dart';

class FandomFormScreen extends StatefulWidget {
  final Fandom? existing;
  const FandomFormScreen({super.key, this.existing});

  @override
  State<FandomFormScreen> createState() => _FandomFormScreenState();
}

class _FandomFormScreenState extends State<FandomFormScreen> {
  final _controller = const FandomController();
  late final TextEditingController _nameCtr;
  late final TextEditingController _descriptionCtr;
  final _tagCtr = TextEditingController();
  String? _categoryId;
  String _coverImageUrl = '';
  String _logoUrl = '';
  List<String> _tags = [];
  bool _isTrending = false;
  bool _isActive = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtr = TextEditingController(text: e?.name ?? '');
    _descriptionCtr = TextEditingController(text: e?.description ?? '');
    _categoryId = (e == null || e.categoryId.isEmpty) ? null : e.categoryId;
    _coverImageUrl = e?.coverImageUrl ?? '';
    _logoUrl = e?.logoUrl ?? '';
    _tags = List<String>.from(e?.tags ?? const []);
    _isTrending = e?.isTrending ?? false;
    _isActive = e?.isActive ?? true;
    _nameCtr.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _descriptionCtr.dispose();
    _tagCtr.dispose();
    super.dispose();
  }

  void _addTags(String raw) {
    final added = _controller.normalizeTags([..._tags, ...raw.split(',')]);
    setState(() {
      _tags = added;
      _tagCtr.clear();
    });
  }

  Future<AppCategory?> _findCategory(String key) async {
    final cats = await CategoryService.instance.fetchCategories();
    final matches = cats.where((c) => c.key == key);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> _save() async {
    if (_tagCtr.text.trim().isNotEmpty) _addTags(_tagCtr.text);
    final name = _nameCtr.text.trim();
    if (_categoryId == null) {
      setState(() => _error = 'Choose a category.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final category = await _findCategory(_categoryId!);
      if (category == null) {
        throw const FandomException(
            'That category no longer exists. Choose another one.');
      }
      final e = widget.existing;
      if (e == null) {
        await FandomService.instance.create(Fandom(
          id: Fandom.slugFor(name),
          categoryId: category.key,
          categoryName: category.name,
          name: name,
          description: _descriptionCtr.text.trim(),
          coverImageUrl: _coverImageUrl,
          logoUrl: _logoUrl,
          tags: _tags,
          isTrending: _isTrending,
          isActive: _isActive,
          createdAt: DateTime.now(),
        ));
      } else {
        await FandomService.instance.update(e.copyWith(
          categoryId: category.key,
          categoryName: category.name,
          name: name,
          description: _descriptionCtr.text.trim(),
          coverImageUrl: _coverImageUrl,
          logoUrl: _logoUrl,
          tags: _tags,
          isTrending: _isTrending,
          isActive: _isActive,
        ));
      }
      if (mounted) Navigator.pop(context);
    } on FandomException catch (err) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = err.message;
        });
      }
    } catch (err) {
      debugPrint('Fandom save failed: $err');
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
    final e = widget.existing;
    final isEdit = e != null;
    final slug = isEdit ? e.id : Fandom.slugFor(_nameCtr.text);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        title: Text(isEdit ? 'Edit Fandom' : 'New Fandom',
            style: AppTheme.orbitron(size: 13)),
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
                    style: AppTheme.orbitron(size: 10, color: AppTheme.orange)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Text(_error!,
                    style: AppTheme.inter(size: 12, color: Colors.redAccent)),
              ),

            _label('Category'),
            CategoryPickerField(
              value: _categoryId,
              accentColor: AppTheme.orange,
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),

            _field('Name', _nameCtr, hint: 'Free Fire'),
            const SizedBox(height: 4),
            Text(
              isEdit
                  ? 'ID: $slug (locked)'
                  : 'ID: ${slug.isEmpty ? '—' : slug}',
              style: AppTheme.inter(size: 10, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _field('Description', _descriptionCtr,
                hint: 'One line about this fandom', maxLines: 3),
            const SizedBox(height: 16),

            _label('Cover Image'),
            ImageUploadField(
              initialUrl: _coverImageUrl,
              accentColor: AppTheme.orange,
              height: 160,
              onUploaded: (url) => setState(() => _coverImageUrl = url),
            ),
            const SizedBox(height: 16),
            _label('Logo'),
            ImageUploadField(
              initialUrl: _logoUrl,
              accentColor: AppTheme.orange,
              height: 110,
              onUploaded: (url) => setState(() => _logoUrl = url),
            ),
            const SizedBox(height: 16),

            _label('Tags'),
            _tagInput(),
            const SizedBox(height: 16),

            if (isEdit) ...[
              _label('Followers'),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text('${e.followerCount}',
                    style: AppTheme.inter(size: 13, color: Colors.grey)),
              ),
              const SizedBox(height: 16),
            ],

            _toggle(
              icon: Icons.local_fire_department_outlined,
              color: AppTheme.pink,
              title: 'Pin to Trending',
              subtitle: 'Always shown first in the Home trending carousel',
              value: _isTrending,
              onChanged: (v) => setState(() => _isTrending = v),
            ),
            const SizedBox(height: 10),
            _toggle(
              icon: Icons.check_circle_outline,
              color: Colors.green,
              title: 'Active',
              subtitle: 'Turn off to hide this fandom (soft delete)',
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTheme.inter(size: 11, color: Colors.grey)),
      );

  Widget _tagInput() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in _tags)
                    InputChip(
                      label: Text(t,
                          style: AppTheme.inter(size: 11, color: Colors.white)),
                      backgroundColor: AppTheme.card,
                      side: BorderSide(
                          color: AppTheme.orange.withValues(alpha: 0.5)),
                      deleteIconColor: Colors.grey,
                      onDeleted: () => setState(() => _tags.remove(t)),
                    ),
                ],
              ),
            ),
          TextField(
            controller: _tagCtr,
            style: AppTheme.inter(size: 13, color: Colors.white),
            textInputAction: TextInputAction.done,
            onChanged: (v) {
              if (v.contains(',')) _addTags(v);
            },
            onSubmitted: _addTags,
            decoration: _decoration(
              'battle royale, mobile',
              suffix: IconButton(
                icon: const Icon(Icons.add, color: AppTheme.orange, size: 18),
                tooltip: 'Add tag',
                onPressed: () => _addTags(_tagCtr.text),
              ),
            ),
          ),
        ],
      );

  Widget _toggle({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTheme.inter(
                          size: 13,
                          color: Colors.white,
                          weight: FontWeight.w600)),
                  Text(subtitle,
                      style: AppTheme.inter(size: 10, color: Colors.grey)),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: color,
              onChanged: onChanged,
            ),
          ],
        ),
      );

  InputDecoration _decoration(String hint, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.inter(size: 13, color: Colors.grey),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.bg,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.orange)),
      );

  Widget _field(String label, TextEditingController ctrl,
          {String? hint, int maxLines = 1}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.inter(size: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: AppTheme.inter(size: 13, color: Colors.white),
            decoration: _decoration(hint ?? ''),
          ),
        ],
      );
}
