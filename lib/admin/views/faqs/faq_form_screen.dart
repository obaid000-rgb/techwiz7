import 'package:flutter/material.dart';
import '../../../models/faq.dart';
import '../../../services/faq_service.dart';
import '../../../theme/app_theme.dart';

class FaqFormScreen extends StatefulWidget {
  final Faq? existing;
  const FaqFormScreen({super.key, this.existing});

  @override
  State<FaqFormScreen> createState() => _FaqFormScreenState();
}

class _FaqFormScreenState extends State<FaqFormScreen> {
  late final _question = TextEditingController(text: widget.existing?.question ?? '');
  late final _answer = TextEditingController(text: widget.existing?.answer ?? '');
  late bool _active = widget.existing?.isActive ?? true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final q = _question.text.trim();
    final a = _answer.text.trim();
    if (q.length < 5 || a.length < 5) {
      setState(() => _error = 'Write a question and an answer (at least 5 characters each).');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = widget.existing;
      if (existing == null) {
        await FaqService.instance.add(question: q, answer: a, isActive: _active);
      } else {
        await FaqService.instance.update(existing.id, question: q, answer: a, isActive: _active);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('FAQ save failed: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Check your connection and try again.';
        });
      }
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.inter(size: 13, color: Colors.grey),
        filled: true,
        fillColor: AppTheme.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.existing == null ? 'New FAQ' : 'Edit FAQ', style: AppTheme.orbitron(size: 13)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(_error!, style: AppTheme.inter(size: 12, color: Colors.redAccent)),
            ),
          Text('Question', style: AppTheme.inter(size: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          TextField(
            controller: _question,
            maxLength: 160,
            minLines: 1,
            maxLines: 3,
            style: AppTheme.inter(size: 14, color: Colors.white),
            decoration: _decoration('e.g. How do I save an event for offline?'),
          ),
          const SizedBox(height: 10),
          Text('Answer', style: AppTheme.inter(size: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          TextField(
            controller: _answer,
            maxLength: 1000,
            minLines: 4,
            maxLines: 10,
            style: AppTheme.inter(size: 14, color: Colors.white),
            decoration: _decoration('The answer fans (and the AI helper) will see'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _active,
            activeThumbColor: AppTheme.accent,
            onChanged: (v) => setState(() => _active = v),
            title: Text('Show on Contact Us', style: AppTheme.inter(size: 13)),
            subtitle: Text('Hidden FAQs are also left out of the AI helper.',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('SAVE FAQ', style: AppTheme.orbitron(size: 12, color: Colors.white, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
