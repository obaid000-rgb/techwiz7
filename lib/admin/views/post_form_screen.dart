import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../models/post.dart';
import '../../services/category_service.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';

class PostFormScreen extends StatefulWidget {
  final Post? existing;
  const PostFormScreen({super.key, this.existing});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _titleCtr = TextEditingController();
  final _contentCtr = TextEditingController();
  final _imageCtr = TextEditingController();
  String? _category;
  bool _saving = false;
  String? _error;
  List<AppCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtr.text = e.title;
      _contentCtr.text = e.content;
      _imageCtr.text = e.imageUrl;
      _category = e.category.isEmpty ? null : e.category;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryService.instance.fetchCategories();
    if (mounted) setState(() => _categories = cats);
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _contentCtr.dispose();
    _imageCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? 'Edit Lore Post' : 'New Lore Post',
            style: AppTheme.orbitron(size: 13)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.cyan.withValues(alpha: 0.3)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Text(_error!,
                    style: AppTheme.inter(size: 12, color: Colors.redAccent)),
              ),
            _label('Title'),
            _textField(_titleCtr, hint: 'Enter lore post title'),
            const SizedBox(height: 16),
            _label('Category'),
            _categoryDropdown(),
            const SizedBox(height: 16),
            _label('Content'),
            _textField(_contentCtr,
                hint: 'Write the lore content...', maxLines: 6),
            const SizedBox(height: 16),
            _label('Image URL (optional)'),
            _textField(_imageCtr,
                hint: 'https://example.com/image.jpg',
                keyboardType: TextInputType.url),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Text('SAVE POST',
                        style: AppTheme.orbitron(
                            size: 12,
                            color: Colors.black,
                            weight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTheme.inter(size: 12, color: Colors.grey)),
      );

  Widget _textField(TextEditingController ctrl,
      {String? hint, int maxLines = 1, TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AppTheme.inter(size: 13, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppTheme.card,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.cyan, width: 1.5)),
        ),
      );

  Widget _categoryDropdown() => Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButton<String>(
          value: _category,
          isExpanded: true,
          dropdownColor: AppTheme.card,
          underline: const SizedBox(),
          hint: Text('Select category',
              style: AppTheme.inter(size: 13, color: Colors.grey)),
          style: AppTheme.inter(size: 13, color: Colors.white),
          items: _categories
              .map((c) => DropdownMenuItem(
                  value: c.key,
                  child: Text(c.name,
                      style: AppTheme.inter(size: 13, color: Colors.white))))
              .toList(),
          onChanged: (v) => setState(() => _category = v),
        ),
      );

  Future<void> _save() async {
    final title = _titleCtr.text.trim();
    final content = _contentCtr.text.trim();
    if (title.isEmpty || content.isEmpty) {
      setState(() => _error = 'Title and content are required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final post = Post(
        id: widget.existing?.id ?? '',
        title: title,
        category: _category ?? '',
        content: content,
        imageUrl: _imageCtr.text.trim(),
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );
      if (widget.existing == null) {
        await PostService.instance.addPost(post);
      } else {
        await PostService.instance.updatePost(post);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Save failed: $e';
        });
      }
    }
  }
}
