import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../models/merchandise.dart';
import '../../services/category_service.dart';
import '../../services/merchandise_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_upload_field.dart';

class MerchandiseFormScreen extends StatefulWidget {
  final Merchandise? existing;
  const MerchandiseFormScreen({super.key, this.existing});

  @override
  State<MerchandiseFormScreen> createState() => _MerchandiseFormScreenState();
}

class _MerchandiseFormScreenState extends State<MerchandiseFormScreen> {
  final _nameCtr = TextEditingController();
  final _priceCtr = TextEditingController();
  final _descCtr = TextEditingController();
  String? _category;
  String _imageUrl = '';
  bool _saving = false;
  String? _error;
  List<AppCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtr.text = e.name;
      _priceCtr.text = e.price.toStringAsFixed(2);
      _imageUrl = e.imageUrl;
      _descCtr.text = e.description;
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
    _nameCtr.dispose();
    _priceCtr.dispose();
    _descCtr.dispose();
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
        title: Text(
            isEdit ? 'Edit Merchandise' : 'New Merchandise',
            style: AppTheme.orbitron(size: 13)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(height: 1, color: AppTheme.orange.withValues(alpha: 0.3)),
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
                    style:
                        AppTheme.inter(size: 12, color: Colors.redAccent)),
              ),
            _label('Name'),
            _textField(_nameCtr, hint: 'Product name'),
            const SizedBox(height: 16),
            _label('Price (USD)'),
            _textField(_priceCtr,
                hint: '24.99',
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true)),
            const SizedBox(height: 16),
            _label('Category'),
            _categoryDropdown(),
            const SizedBox(height: 16),
            _label('Image (optional)'),
            ImageUploadField(
              initialUrl: _imageUrl.isEmpty ? null : _imageUrl,
              onUploaded: (url) => setState(() => _imageUrl = url),
              accentColor: AppTheme.orange,
            ),
            const SizedBox(height: 16),
            _label('Description'),
            _textField(_descCtr,
                hint: 'Describe the product...', maxLines: 4),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('SAVE ITEM',
                        style: AppTheme.orbitron(
                            size: 12,
                            color: Colors.white,
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
        child:
            Text(text, style: AppTheme.inter(size: 12, color: Colors.grey)),
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
              borderSide: const BorderSide(
                  color: AppTheme.orange, width: 1.5)),
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
    final name = _nameCtr.text.trim();
    final price = double.tryParse(_priceCtr.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = 'Enter a valid price.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final item = Merchandise(
        id: widget.existing?.id ?? '',
        name: name,
        price: price,
        category: _category ?? '',
        imageUrl: _imageUrl,
        description: _descCtr.text.trim(),
      );
      if (widget.existing == null) {
        await MerchandiseService.instance.addMerchandise(item);
      } else {
        await MerchandiseService.instance.updateMerchandise(item);
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
