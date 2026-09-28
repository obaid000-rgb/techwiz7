import 'package:flutter/material.dart';
import '../../../models/team_member.dart';
import '../../../services/team_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/image_upload_field.dart';

class TeamMemberFormScreen extends StatefulWidget {
  final TeamMember? existing;
  const TeamMemberFormScreen({super.key, this.existing});

  @override
  State<TeamMemberFormScreen> createState() => _TeamMemberFormScreenState();
}

class _TeamMemberFormScreenState extends State<TeamMemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _role = TextEditingController(text: widget.existing?.role ?? '');
  late final _bio = TextEditingController(text: widget.existing?.bio ?? '');
  late String _imageUrl = widget.existing?.imageUrl ?? '';
  bool _saving = false;
  bool _imageBusy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBusy) {
      setState(() => _error = 'Wait for the image to finish uploading.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = widget.existing;
      if (existing == null) {
        await TeamService.instance.add(
            name: _name.text.trim(), role: _role.text.trim(), bio: _bio.text.trim(), imageUrl: _imageUrl);
      } else {
        await TeamService.instance.update(existing.id,
            name: _name.text.trim(), role: _role.text.trim(), bio: _bio.text.trim(), imageUrl: _imageUrl);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Team member save failed: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Check your connection and try again.';
        });
      }
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
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

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: AppTheme.inter(size: 12, color: Colors.grey)),
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
        title: Text(widget.existing == null ? 'New Team Member' : 'Edit Team Member',
            style: AppTheme.orbitron(size: 13)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ImageUploadField(
                initialUrl: _imageUrl.isEmpty ? null : _imageUrl,
                onUploaded: (url) => setState(() => _imageUrl = url),
                onBusyChanged: (busy) {
                  if (mounted) setState(() => _imageBusy = busy);
                },
                accentColor: AppTheme.accent,
                isCircular: true,
                circleRadius: 52,
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('Tap to upload a photo (optional)',
                  style: AppTheme.inter(size: 11, color: Colors.grey)),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: AppTheme.inter(size: 12, color: Colors.redAccent)),
              ),
            _label('Name'),
            TextFormField(
              controller: _name,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              style: AppTheme.inter(size: 14, color: Colors.white),
              decoration: _dec('Full name'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a name.' : null,
            ),
            const SizedBox(height: 8),
            _label('Role / designation'),
            TextFormField(
              controller: _role,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              style: AppTheme.inter(size: 14, color: Colors.white),
              decoration: _dec('e.g. Flutter Developer'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a role.' : null,
            ),
            const SizedBox(height: 8),
            _label('Short bio (optional)'),
            TextFormField(
              controller: _bio,
              maxLength: 200,
              minLines: 3,
              maxLines: 5,
              style: AppTheme.inter(size: 14, color: Colors.white),
              decoration: _dec('One or two sentences'),
            ),
            const SizedBox(height: 16),
            if (_imageBusy)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Wait for the image to finish uploading',
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
              ),
            ElevatedButton(
              onPressed: _saving || _imageBusy ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('SAVE', style: AppTheme.orbitron(size: 12, color: Colors.white, weight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
