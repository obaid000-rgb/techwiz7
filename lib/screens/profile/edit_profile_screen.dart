import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_upload_field.dart';

/// Instagram-style Edit Profile: name, bio and avatar. Nothing is written to
/// Firestore until SAVE; backing out discards the changes.
class EditProfileScreen extends StatefulWidget {
  final UserData user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const int _maxName = 40;
  static const int _maxBio = 160;

  late final TextEditingController _nameCtr = TextEditingController(text: widget.user.name);
  late final TextEditingController _bioCtr = TextEditingController(text: widget.user.bio);
  late String _avatarUrl = widget.user.avatarUrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtr.addListener(_refresh);
    _bioCtr.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _nameCtr.dispose();
    _bioCtr.dispose();
    super.dispose();
  }

  String get _name => _nameCtr.text.trim();
  String get _bio => _bioCtr.text.trim();

  bool get _dirty =>
      _name != widget.user.name || _bio != widget.user.bio || _avatarUrl != widget.user.avatarUrl;

  Future<void> _save() async {
    if (_name.isEmpty) {
      setState(() => _error = 'Name can\'t be empty.');
      return;
    }
    if (!_dirty) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final original = widget.user;
    try {
      // Only the fields that actually changed are sent.
      await UserService.instance.updateProfileBasics(
        original.uid,
        name: _name != original.name ? _name : null,
        bio: _bio != original.bio ? _bio : null,
        avatarUrl: _avatarUrl != original.avatarUrl ? _avatarUrl : null,
      );
      final current = AuthService.instance.currentUser ?? original;
      AuthService.instance.userNotifier.value =
          current.copyWith(name: _name, bio: _bio, avatarUrl: _avatarUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), duration: Duration(seconds: 2)),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your profile. Check your connection and try again.';
        });
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty || _saving) return !_saving;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Discard changes?', style: AppTheme.orbitron(size: 13, color: Colors.white)),
        content: Text('Your edits to your profile won\'t be saved.',
            style: AppTheme.inter(size: 12, color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('KEEP EDITING', style: AppTheme.orbitron(size: 9, color: AppTheme.cyan)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DISCARD', style: AppTheme.orbitron(size: 9, color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _cancel() async {
    if (await _confirmDiscard() && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          backgroundColor: AppTheme.card,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Cancel',
            onPressed: _saving ? null : _cancel,
          ),
          title: Text('Edit Profile', style: AppTheme.orbitron(size: 13)),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan))
                  : Text('SAVE',
                      style: AppTheme.orbitron(
                          size: 11, color: _dirty ? AppTheme.cyan : Colors.white38, weight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AbsorbPointer(
              absorbing: _saving,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  ImageUploadField(
                    initialUrl: _avatarUrl.isEmpty ? null : _avatarUrl,
                    onUploaded: (url) => setState(() => _avatarUrl = url),
                    accentColor: AppTheme.cyan,
                    isCircular: true,
                    circleRadius: 52,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text('Tap the photo to change it',
                        style: AppTheme.inter(size: 12, color: AppTheme.cyan)),
                  ),
                  const SizedBox(height: 28),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: AppTheme.inter(size: 12, color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _label('Name'),
                  _field(_nameCtr, hint: 'Your display name', maxLength: _maxName, maxLines: 1),
                  const SizedBox(height: 14),
                  _label('Bio'),
                  _field(_bioCtr,
                      hint: 'Tell other fans a bit about yourself…', maxLength: _maxBio, maxLines: 4),
                  const SizedBox(height: 14),
                  _label('Email'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.card.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(widget.user.email,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.inter(size: 13, color: Colors.white54)),
                        ),
                        const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cyan,
                        disabledBackgroundColor: AppTheme.border,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text('SAVE CHANGES',
                              style: AppTheme.orbitron(size: 11, color: Colors.black, weight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: _saving ? null : _cancel,
                      child: Text('Cancel', style: AppTheme.inter(size: 13, color: Colors.white60)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(text, style: AppTheme.inter(size: 12, color: Colors.grey, weight: FontWeight.w600)),
      );

  Widget _field(TextEditingController ctrl,
          {required String hint, required int maxLength, required int maxLines}) =>
      TextField(
        controller: ctrl,
        maxLength: maxLength,
        maxLines: maxLines,
        minLines: 1,
        textCapitalization:
            maxLines == 1 ? TextCapitalization.words : TextCapitalization.sentences,
        style: AppTheme.inter(size: 14, color: Colors.white),
        decoration: InputDecoration(hintText: hint),
      );
}
