import 'package:flutter/material.dart';
import '../../../services/admin_user_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_db.dart';
import '../../../services/user_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/levels.dart';
import '../../../utils/validators.dart';
import '../../../widgets/avatar_view.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserData>>(
      stream: UserService.instance.watchUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent));
        }
        if (snapshot.hasError) {
          debugPrint('Users load error: ${snapshot.error}');
          return Center(
              child: Text('Could not load users. Check your connection and try again.',
                  style: AppTheme.inter(color: Colors.redAccent)));
        }
        final users = snapshot.data ?? [];
        return Column(
          children: [
            _header(context),
            Expanded(
              child: users.isEmpty
                  ? _empty()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: users.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          _userRow(context, users[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Users', style: AppTheme.orbitron(size: 13)),
            ElevatedButton.icon(
              onPressed: () => _showAddInfoDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.person_add_alt_1, size: 16),
              label: Text('ADD', style: AppTheme.orbitron(size: 9)),
            ),
          ],
        ),
      );

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, color: Colors.grey, size: 36),
            const SizedBox(height: 12),
            Text('No users found',
                style: AppTheme.inter(size: 13, color: Colors.grey)),
          ],
        ),
      );

  Widget _userRow(BuildContext context, UserData user) {
    final isAdmin = user.role == 'admin';
    final isSelf = user.uid == AuthService.instance.currentUser?.uid;
    final cats = user.categories.isEmpty
        ? 'No categories'
        : user.categories.join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin
              ? AppTheme.orange.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          AvatarView.user(user, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name.isEmpty ? '(no name)' : user.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(
                            size: 13, weight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppTheme.orange.withValues(alpha: 0.15)
                            : AppTheme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isAdmin ? AppTheme.orange : AppTheme.accent,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isAdmin ? 'ADMIN' : 'FAN',
                        style: AppTheme.orbitron(
                          size: 8,
                          color: isAdmin ? AppTheme.orange : AppTheme.accent,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (user.disabled) ...[
                  const SizedBox(height: 3),
                  Text('DEACTIVATED',
                      style: AppTheme.orbitron(
                          size: 8, color: Colors.redAccent, weight: FontWeight.w700)),
                ],
                const SizedBox(height: 2),
                Text(user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(size: 10, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(cats,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTheme.inter(size: 10, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.cyan, size: 18),
            onPressed: () => _showEditDialog(context, user),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(
                user.disabled ? Icons.check_circle_outline : Icons.block,
                color: isSelf
                    ? Colors.grey
                    : (user.disabled ? Colors.greenAccent : AppTheme.orange),
                size: 18),
            onPressed: isSelf ? null : () => _confirmSetDisabled(context, user),
            tooltip: isSelf
                ? "You can't deactivate your own account"
                : (user.disabled ? 'Activate' : 'Deactivate'),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: isSelf ? Colors.grey : Colors.redAccent, size: 18),
            onPressed: isSelf ? null : () => _confirmDelete(context, user),
            tooltip: isSelf ? "You can't delete your own account" : 'Delete',
          ),
        ],
      ),
    );
  }

  Future<void> _showAddInfoDialog(BuildContext context) => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _AddUserDialog(),
      );

  Future<void> _showEditDialog(BuildContext context, UserData user) =>
      showDialog(
        context: context,
        builder: (_) => _UserEditDialog(user: user),
      );

  Future<void> _confirmSetDisabled(BuildContext context, UserData user) async {
    final deactivate = !user.disabled;
    final who = user.name.isEmpty ? user.email : user.name;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(deactivate ? 'Deactivate "$who"?' : 'Activate "$who"?',
            style: AppTheme.orbitron(size: 12, color: Colors.white)),
        content: Text(
          deactivate
              ? 'They will be signed out right away and can\'t use their '
                  'account until you activate it again. Their data is kept.'
              : 'They will be able to sign in and use their account again.',
          style: AppTheme.inter(size: 12, color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL',
                style: AppTheme.orbitron(size: 9, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(deactivate ? 'DEACTIVATE' : 'ACTIVATE',
                style: AppTheme.orbitron(
                    size: 9,
                    color: deactivate ? AppTheme.orange : Colors.greenAccent)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await UserService.instance.setDisabled(user.uid, deactivate);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(deactivate ? '$who deactivated' : '$who activated')));
    } catch (e) {
      debugPrint('User status change failed: $e');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Could not update. Check your connection.')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, UserData user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove "${user.name.isEmpty ? user.email : user.name}"?',
            style: AppTheme.orbitron(size: 12, color: Colors.white)),
        content: Text(
          'This deletes the Firestore profile document only.\n\n'
          'It does NOT delete their Firebase Authentication login — '
          'they can still sign in and a new profile will be created. '
          'To fully remove the account, also delete the user from '
          'Firebase Console → Authentication.\n\n'
          'To block someone from using the app, use Deactivate instead.',
          style: AppTheme.inter(size: 12, color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL',
                style: AppTheme.orbitron(size: 9, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('REMOVE PROFILE',
                style:
                    AppTheme.orbitron(size: 9, color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await UserService.instance.deleteUser(user.uid);
    } catch (e) {
      debugPrint('User delete failed: $e');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Could not delete. Check your connection.')));
    }
  }
}

// ── Edit dialog ───────────────────────────────────────────────────────────────

class _UserEditDialog extends StatefulWidget {
  final UserData user;
  const _UserEditDialog({required this.user});

  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  late final TextEditingController _nameCtr;
  late final TextEditingController _xpCtr;
  late String _role;
  bool _saving = false;
  bool _nameAttempted = false;
  String? _error;
  // An admin demoting themselves would lock themselves out of the panel.
  late final bool _isSelf =
      widget.user.uid == AuthService.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _nameCtr = TextEditingController(text: widget.user.name);
    _xpCtr = TextEditingController(text: '${widget.user.xp}');
    _role = widget.user.role;
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _xpCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.card,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Edit User',
          style: AppTheme.orbitron(size: 13, color: Colors.white)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.user.email,
                style: AppTheme.inter(size: 11, color: Colors.grey)),
            const SizedBox(height: 14),
            Text('Name',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            TextField(
              controller: _nameCtr,
              onChanged: (_) {
                if (_nameAttempted) setState(() {});
              },
              style: AppTheme.inter(size: 13, color: Colors.white),
              decoration: InputDecoration(
                errorText: _nameAttempted ? _nameError : null,
                errorMaxLines: 2,
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
                        const BorderSide(color: AppTheme.accent)),
              ),
            ),
            const SizedBox(height: 14),
            Text('Role',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: ['fan', 'admin'].map((r) {
                final isSelected = _role == r;
                final color =
                    r == 'admin' ? AppTheme.orange : AppTheme.accent;
                return Expanded(
                  child: GestureDetector(
                    onTap: _isSelf ? null : () => setState(() => _role = r),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : AppTheme.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? color : AppTheme.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        r.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: AppTheme.orbitron(
                          size: 10,
                          color: isSelected ? color : Colors.grey,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_isSelf) ...[
              const SizedBox(height: 6),
              Text("You can't change your own role",
                  style: AppTheme.inter(size: 10, color: Colors.grey)),
            ],
            const SizedBox(height: 14),
            Text('XP (Level ${levelFor(int.tryParse(_xpCtr.text.trim()) ?? widget.user.xp)})',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            TextField(
              controller: _xpCtr,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              style: AppTheme.inter(size: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: '0',
                helperText: '100 · 250 · 500 (Deep Dive) · 1000 (max)',
                helperStyle: AppTheme.inter(size: 10, color: Colors.grey),
                errorText: _xpError,
                filled: true,
                fillColor: AppTheme.bg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.accent)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: AppTheme.inter(size: 12, color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL',
              style: AppTheme.orbitron(size: 9, color: Colors.grey)),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.accent))
              : Text('SAVE',
                  style:
                      AppTheme.orbitron(size: 9, color: AppTheme.accent)),
        ),
      ],
    );
  }

  String? get _nameError => _nameCtr.text.trim() == widget.user.name.trim()
      ? null
      : Validators.validateName(_nameCtr.text);

  String? get _xpError {
    final v = int.tryParse(_xpCtr.text.trim());
    if (v == null || v < 0 || v > 1000000) return 'Enter a whole number from 0 to 1,000,000';
    return null;
  }

  Future<void> _save() async {
    if (_nameError != null) {
      setState(() => _nameAttempted = true);
      return;
    }
    if (_xpError != null) {
      setState(() {});
      return;
    }
    final xp = int.parse(_xpCtr.text.trim());
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Write only the fields this dialog edits. A full UserData.toMap()
      // here would reset every other field (bio, badge, bookmarks, …).
      await FirestoreDb.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
        'name': _nameCtr.text.trim(),
        if (!_isSelf) 'role': _role,
        if (xp != widget.user.xp) 'xp': xp,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('User update failed: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Check your connection and try again.';
        });
      }
    }
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'fan';
  bool _saving = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AdminUserService.instance.createUser(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        role: _role,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text('Account created for ${_email.text.trim()}.')));
    } catch (e) {
      debugPrint('Add user failed: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e is AdminUserException
              ? e.message
              : 'Could not create the account. Check your connection and try again.';
        });
      }
    }
  }

  InputDecoration _dec(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        labelStyle: AppTheme.inter(size: 12, color: Colors.grey),
        isDense: true,
        suffixIcon: suffix,
        errorMaxLines: 3,
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Add user', style: AppTheme.orbitron(size: 13, color: Colors.white)),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  style: AppTheme.inter(size: 13, color: Colors.white),
                  decoration: _dec('Name'),
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _email,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTheme.inter(size: 13, color: Colors.white),
                  decoration: _dec('Email'),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _password,
                  enabled: !_saving,
                  obscureText: _hidePassword,
                  style: AppTheme.inter(size: 13, color: Colors.white),
                  decoration: _dec('Password',
                      suffix: IconButton(
                        icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18, color: Colors.grey),
                        onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      )),
                  validator: Validators.validateNewPassword,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  dropdownColor: AppTheme.card,
                  style: AppTheme.inter(size: 13, color: Colors.white),
                  decoration: _dec('Role'),
                  items: const [
                    DropdownMenuItem(value: 'fan', child: Text('Fan')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _role = v ?? 'fan'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: AppTheme.inter(size: 12, color: Colors.redAccent)),
                ],
                const SizedBox(height: 8),
                Text('The new user picks their interests when they first sign in.',
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text('CANCEL', style: AppTheme.orbitron(size: 9, color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _create,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('CREATE', style: AppTheme.orbitron(size: 9, color: Colors.white)),
        ),
      ],
    );
  }
}
