import 'package:flutter/material.dart';
import '../../../models/onboarding_slide.dart';
import '../../../services/onboarding_slide_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/image_upload_field.dart';

class OnboardingSlideFormScreen extends StatefulWidget {
  final OnboardingSlide? existing;
  const OnboardingSlideFormScreen({super.key, this.existing});

  @override
  State<OnboardingSlideFormScreen> createState() =>
      _OnboardingSlideFormScreenState();
}

class _OnboardingSlideFormScreenState extends State<OnboardingSlideFormScreen> {
  late final TextEditingController _titleCtr;
  late final TextEditingController _descriptionCtr;
  String _imageUrl = '';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtr = TextEditingController(text: e?.title ?? '');
    _descriptionCtr = TextEditingController(text: e?.description ?? '');
    _imageUrl = e?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _descriptionCtr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtr.text.trim();
    final description = _descriptionCtr.text.trim();
    if (title.isEmpty || description.isEmpty) {
      setState(() => _error = 'Title and description are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final e = widget.existing;
      if (e == null) {
        await OnboardingSlideService.instance.addSlide(OnboardingSlide(
          id: '',
          title: title,
          description: description,
          imageUrl: _imageUrl,
        ));
      } else {
        await OnboardingSlideService.instance.updateSlide(e.copyWith(
          title: title,
          description: description,
          imageUrl: _imageUrl,
        ));
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
        title: Text(isEdit ? 'Edit Slide' : 'New Slide',
            style: AppTheme.orbitron(size: 13)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.pink),
                  )
                : Text('SAVE',
                    style: AppTheme.orbitron(size: 10, color: AppTheme.pink)),
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
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Text(_error!,
                    style: AppTheme.inter(size: 12, color: Colors.redAccent)),
              ),
            Text('Illustration (square works best)',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            ImageUploadField(
              initialUrl: _imageUrl.isEmpty ? null : _imageUrl,
              accentColor: AppTheme.pink,
              height: 200,
              onUploaded: (url) => setState(() => _imageUrl = url),
            ),
            const SizedBox(height: 16),
            _field('Title', _titleCtr, hint: 'Explore Your Fandoms'),
            const SizedBox(height: 12),
            _field('Description', _descriptionCtr,
                hint: 'One or two short sentences shown under the title',
                maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.inter(size: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: AppTheme.inter(size: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
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
                  borderSide: const BorderSide(color: AppTheme.pink)),
            ),
          ),
        ],
      );
}
