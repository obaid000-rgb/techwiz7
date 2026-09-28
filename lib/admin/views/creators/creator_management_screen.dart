import 'package:flutter/material.dart';
import '../../../models/creator.dart';
import '../../../services/creator_service.dart';
import '../../../theme/app_theme.dart';
import 'creator_form_screen.dart';

class CreatorManagementScreen extends StatefulWidget {
  const CreatorManagementScreen({super.key});

  @override
  State<CreatorManagementScreen> createState() =>
      _CreatorManagementScreenState();
}

class _CreatorManagementScreenState extends State<CreatorManagementScreen> {
  late final Stream<List<Creator>> _creators =
      CreatorService.instance.watchAll();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                  child: Text('Creators', style: AppTheme.orbitron(size: 13))),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatorFormScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text('ADD', style: AppTheme.orbitron(size: 9)),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Creator>>(
            stream: _creators,
            builder: (context, snap) {
              if (snap.hasError) {
                debugPrint('Creators load error: ${snap.error}');
                return Center(
                  child: Text(
                      'Could not load creators. Check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: AppTheme.inter(color: Colors.red)),
                );
              }
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: AppTheme.orange));
              }
              final creators = snap.data!;
              if (creators.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.record_voice_over_outlined,
                          color: Colors.grey, size: 36),
                      const SizedBox(height: 12),
                      Text('No creators yet',
                          style: AppTheme.inter(size: 13, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Tap ADD to create the first one',
                          style: AppTheme.inter(size: 11, color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: creators.length,
                itemBuilder: (context, i) => _row(creators[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _row(Creator c) => Container(
        key: ValueKey(c.id),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: c.isActive
                  ? AppTheme.border
                  : Colors.redAccent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: c.isActive ? 1 : 0.5,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.orange.withValues(alpha: 0.15),
                backgroundImage:
                    c.avatarUrl.isNotEmpty ? NetworkImage(c.avatarUrl) : null,
                onBackgroundImageError:
                    c.avatarUrl.isNotEmpty ? (e, st) {} : null,
                child: c.avatarUrl.isEmpty
                    ? Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                        style: AppTheme.orbitron(size: 14, color: AppTheme.orange))
                    : null,
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
                        child: Text(c.name,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.orbitron(
                                size: 11,
                                weight: FontWeight.w700,
                                color: c.isActive ? Colors.white : Colors.grey)),
                      ),
                      if (c.isVerified) ...[
                        const SizedBox(width: 5),
                        const Tooltip(
                          message: 'Verified',
                          child: Icon(Icons.verified_rounded,
                              color: AppTheme.cyan, size: 14),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(kCreatorKindLabels[c.kind] ?? c.kind,
                      style: AppTheme.inter(size: 10, color: Colors.grey)),
                  if (!c.isActive) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.redAccent, width: 0.5),
                      ),
                      child: Text('Inactive',
                          style:
                              AppTheme.inter(size: 9, color: Colors.redAccent)),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined,
                  color: AppTheme.cyan, size: 18),
              tooltip: 'Edit',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CreatorFormScreen(existing: c)),
              ),
            ),
            if (c.isActive)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 18),
                tooltip: 'Deactivate',
                onPressed: () => _confirmDeactivate(c),
              )
            else
              TextButton(
                onPressed: () => _run(() => CreatorService.instance.restore(c.id),
                    '"${c.name}" restored'),
                child: Text('RESTORE',
                    style: AppTheme.orbitron(size: 8, color: Colors.green)),
              ),
          ],
        ),
      );

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      debugPrint('Creator action failed: $e');
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not save. Check your connection and try again.')));
    }
  }

  Future<void> _confirmDeactivate(Creator c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Deactivate "${c.name}"?',
            style: AppTheme.orbitron(size: 12, color: Colors.white)),
        content: Text(
            'It will be marked Inactive and hidden from the creator list in the post form. Posts keep their creator. You can restore it at any time.',
            style: AppTheme.inter(size: 12, color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL',
                style: AppTheme.orbitron(size: 9, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DEACTIVATE',
                style: AppTheme.orbitron(size: 9, color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => CreatorService.instance.softDelete(c.id),
          '"${c.name}" deactivated');
    }
  }
}
