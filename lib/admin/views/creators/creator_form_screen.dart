import 'package:flutter/material.dart';
import '../../../models/creator.dart';
import '../../../services/creator_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/image_upload_field.dart';
import '../../widgets/fandom_picker_fields.dart';

class CreatorFormScreen extends StatefulWidget {
  final Creator? existing;
  const CreatorFormScreen({super.key, this.existing});

  @override
  State<CreatorFormScreen> createState() => _CreatorFormScreenState();
}

class _CreatorFormScreenState extends State<CreatorFormScreen> {
  late final TextEditingController _nameCtr;
  late final TextEditingController _bioCtr;
  String _avatarUrl = '';
  String _kind = 'community';
  List<String> _fandomIds = [];
  bool _isVerified = false;
  bool _isActive = true;
  bool _saving = false;
  bool _imageBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtr = TextEditingController(text: e?.name ?? '');
    _bioCtr = TextEditingController(text: e?.bio ?? '');
    _avatarUrl = e?.avatarUrl ?? '';
    _kind = e?.kind ?? 'community';
    _fandomIds = List.of(e?.fandomIds ?? const []);
    _isVerified = e?.isVerified ?? false;
    _isActive = e?.isActive ?? true;
    _nameCtr.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _bioCtr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtr.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (_imageBusy) {
      setState(() => _error = 'Wait for the image to finish uploading.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final e = widget.existing;
      if (e == null) {
        await CreatorService.instance.create(Creator(
          id: Creator.slugFor(name),
          name: name,
          avatarUrl: _avatarUrl,
          kind: _kind,
          bio: _bioCtr.text.trim(),
          fandomIds: _fandomIds,
          isVerified: _isVerified,
          isActive: _isActive,
          createdAt: DateTime.now(),
        ));
      } else {
        await CreatorService.instance.update(e.copyWith(
          name: name,
          avatarUrl: _avatarUrl,
          kind: _kind,
          bio: _bioCtr.text.trim(),
          fandomIds: _fandomIds,
          isVerified: _isVerified,
          isActive: _isActive,
        ));
      }
      if (mounted) Navigator.pop(context);
    } on CreatorException catch (err) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = err.message;
        });
      }
    } catch (err) {
      debugPrint('Creator save failed: $err');
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
    final slug = e?.id ?? Creator.slugFor(_nameCtr.text);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        title: Text(e == null ? 'New Creator' : 'Edit Creator',
            style: AppTheme.orbitron(size: 13)),
        actions: [
          TextButton(
            onPressed: _saving || _imageBusy ? null : _save,
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
                width: double.infinity,
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
            Center(
              child: ImageUploadField(
                initialUrl: _avatarUrl,
                isCircular: true,
                accentColor: AppTheme.orange,
                onUploaded: (url) => setState(() => _avatarUrl = url),
                onBusyChanged: (busy) {
                  if (mounted) setState(() => _imageBusy = busy);
                },
              ),
            ),
            if (_imageBusy)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Center(
                  child: Text('Wait for the image to finish uploading',
                      style: AppTheme.inter(size: 10, color: Colors.grey)),
                ),
              ),
            const SizedBox(height: 16),
            _label('Name'),
            _textField(_nameCtr, hint: 'Crunchyroll'),
            const SizedBox(height: 4),
            Text(e == null ? 'ID: ${slug.isEmpty ? '—' : slug}' : 'ID: $slug (locked)',
                style: AppTheme.inter(size: 10, color: Colors.grey)),
            const SizedBox(height: 14),
            _label('Kind'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButton<String>(
                value: _kind,
                isExpanded: true,
                dropdownColor: AppTheme.card,
                underline: const SizedBox.shrink(),
                style: AppTheme.inter(size: 13, color: Colors.white),
                items: [
                  for (final k in kCreatorKinds)
                    DropdownMenuItem(value: k, child: Text(kCreatorKindLabels[k]!)),
                ],
                onChanged: (v) => setState(() => _kind = v ?? _kind),
              ),
            ),
            const SizedBox(height: 14),
            _label('Bio'),
            _textField(_bioCtr, hint: 'Who they are, in a line or two', maxLines: 3),
            const SizedBox(height: 16),
            FandomMultiPicker(
              initialIds: _fandomIds,
              accentColor: AppTheme.orange,
              onChanged: (ids) => setState(() => _fandomIds = ids),
            ),
            const SizedBox(height: 16),
            _toggle(Icons.verified_rounded, AppTheme.cyan, 'Verified',
                'Shows a verified badge next to the creator', _isVerified,
                (v) => setState(() => _isVerified = v)),
            const SizedBox(height: 10),
            _toggle(Icons.check_circle_outline, Colors.green, 'Active',
                'Turn off to hide this creator (soft delete)', _isActive,
                (v) => setState(() => _isActive = v)),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTheme.inter(size: 11, color: Colors.grey)),
      );

  Widget _textField(TextEditingController ctrl,
          {String? hint, int maxLines = 1}) =>
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
              borderSide: const BorderSide(color: AppTheme.orange)),
        ),
      );

  Widget _toggle(IconData icon, Color color, String title, String subtitle,
          bool value, ValueChanged<bool> onChanged) =>
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
                          size: 13, color: Colors.white, weight: FontWeight.w600)),
                  Text(subtitle,
                      style: AppTheme.inter(size: 10, color: Colors.grey)),
                ],
              ),
            ),
            Switch(value: value, activeThumbColor: color, onChanged: onChanged),
          ],
        ),
      );
}
