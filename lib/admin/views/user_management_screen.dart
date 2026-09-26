import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_db.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

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
          CircleAvatar(
            radius: 20,
            backgroundColor: isAdmin
                ? AppTheme.orange.withValues(alpha: 0.2)
                : AppTheme.accent.withValues(alpha: 0.2),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
              color: isAdmin ? AppTheme.orange : AppTheme.accent,
              size: 20,
            ),
          ),
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
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 18),
            onPressed: () => _confirmDelete(context, user),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  Future<void> _showAddInfoDialog(BuildContext context) => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.cyan, size: 20),
              const SizedBox(width: 8),
              Text('Adding users',
                  style: AppTheme.orbitron(size: 12, color: Colors.white)),
            ],
          ),
          content: Text(
            'New accounts are created via:\n\n'
            '1. Self-registration in the app (Register screen)\n'
            '2. Manual creation in Firebase Console →\n'
            '   Authentication → Users → Add user\n\n'
            'To grant admin role: create the account, then set\n'
            'role = "admin" via Edit in this screen.',
            style: AppTheme.inter(size: 12, color: Colors.grey, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('GOT IT',
                  style: AppTheme.orbitron(size: 9, color: AppTheme.cyan)),
            ),
          ],
        ),
      );

  Future<void> _showEditDialog(BuildContext context, UserData user) =>
      showDialog(
        context: context,
        builder: (_) => _UserEditDialog(user: user),
      );

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
          'Firebase Console → Authentication.',
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

    if (confirm == true) {
      await UserService.instance.deleteUser(user.uid);
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
  late String _role;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtr = TextEditingController(text: widget.user.name);
    _role = widget.user.role;
  }

  @override
  void dispose() {
    _nameCtr.dispose();
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
              style: AppTheme.inter(size: 13, color: Colors.white),
              decoration: InputDecoration(
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
                    onTap: () => setState(() => _role = r),
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Write only the fields this dialog edits. A full UserData.toMap()
      // here would reset every other field (bio, badge, bookmarks, …).
      await FirestoreDb.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
        'name': _nameCtr.text.trim(),
        'role': _role,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }
}
