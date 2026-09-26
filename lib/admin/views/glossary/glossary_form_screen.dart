import 'package:flutter/material.dart';
import '../../../models/glossary_term.dart';
import '../../../services/glossary_service.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/category_picker_field.dart';

class GlossaryFormScreen extends StatefulWidget {
  final GlossaryTerm? existing;
  const GlossaryFormScreen({super.key, this.existing});

  @override
  State<GlossaryFormScreen> createState() => _GlossaryFormScreenState();
}

class _GlossaryFormScreenState extends State<GlossaryFormScreen> {
  final _termCtr = TextEditingController();
  final _definitionCtr = TextEditingController();
  String? _category;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _termCtr.text = e.term;
      _definitionCtr.text = e.definition;
      _category = e.category.isEmpty ? null : e.category;
    }
  }

  @override
  void dispose() {
    _termCtr.dispose();
    _definitionCtr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final term = _termCtr.text.trim();
    final definition = _definitionCtr.text.trim();
    if (term.isEmpty || definition.isEmpty) {
      setState(() => _error = 'Term and definition are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final e = widget.existing;
      if (e == null) {
        await GlossaryService.instance.addTerm(GlossaryTerm(
          id: '',
          term: term,
          definition: definition,
          category: _category ?? '',
        ));
      } else {
        await GlossaryService.instance.updateTerm(
          e.copyWith(term: term, definition: definition, category: _category ?? ''),
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? 'Edit Term' : 'New Term', style: AppTheme.orbitron(size: 13)),
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
            _label('Term'),
            _textField(_termCtr, hint: 'e.g. Canon, OTP, Headcanon'),
            const SizedBox(height: 16),
            _label('Definition'),
            _textField(_definitionCtr, hint: 'Explain the term…', maxLines: 5),
            const SizedBox(height: 16),
            _label('Related Category (optional)'),
            CategoryPickerField(
              value: _category,
              accentColor: AppTheme.accent,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('SAVE TERM',
                        style: AppTheme.orbitron(size: 12, color: Colors.white, weight: FontWeight.w800)),
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

  Widget _textField(TextEditingController ctrl, {String? hint, int maxLines = 1}) => TextField(
        controller: ctrl,
        maxLines: maxLines,
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
              borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
        ),
      );
}
