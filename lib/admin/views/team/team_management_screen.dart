import 'package:flutter/material.dart';
import '../../../models/team_member.dart';
import '../../../services/team_service.dart';
import '../../../theme/app_theme.dart';
import 'team_member_form_screen.dart';

/// Admin: the About Us "Meet the Team" members.
class TeamManagementScreen extends StatelessWidget {
  const TeamManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TeamMember>>(
      stream: TeamService.instance.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Team load error: ${snapshot.error}');
          return Center(
              child: Text('Could not load team members. Check your connection and try again.',
                  style: AppTheme.inter(color: Colors.redAccent)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
        }
        final team = snapshot.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('About Us · Team', style: AppTheme.orbitron(size: 13)),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const TeamMemberFormScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: Text('ADD', style: AppTheme.orbitron(size: 9)),
                  ),
                ],
              ),
            ),
            if (team.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text('Drag the handle to change the order shown on About Us.',
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
              ),
            Expanded(
              child: team.isEmpty
                  ? Center(
                      child: Text('No team members yet. Tap ADD to add the first one.',
                          style: AppTheme.inter(size: 13, color: Colors.grey)),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      buildDefaultDragHandles: false,
                      itemCount: team.length,
                      // ignore: deprecated_member_use
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final reordered = List<TeamMember>.from(team);
                        reordered.insert(newIndex, reordered.removeAt(oldIndex));
                        TeamService.instance.reorder(reordered).catchError((Object e) {
                          debugPrint('Team reorder failed: $e');
                        });
                      },
                      itemBuilder: (context, i) => _row(context, team[i], i),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, TeamMember m, int index) => Container(
        key: ValueKey(m.id),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(4, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
              ),
            ),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
              backgroundImage: m.imageUrl.isNotEmpty ? NetworkImage(m.imageUrl) : null,
              onBackgroundImageError: m.imageUrl.isNotEmpty ? (e, s) {} : null,
              child: m.imageUrl.isEmpty
                  ? Text(m.name.trim().isEmpty ? '?' : m.name.trim()[0].toUpperCase(),
                      style: AppTheme.orbitron(size: 14, weight: FontWeight.w800))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 13, weight: FontWeight.w600)),
                  Text(m.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 11, color: AppTheme.pink)),
                  if (m.bio.isNotEmpty)
                    Text(m.bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 11, color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.cyan, size: 18),
              tooltip: 'Edit',
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => TeamMemberFormScreen(existing: m))),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, m),
            ),
          ],
        ),
      );

  Future<void> _confirmDelete(BuildContext context, TeamMember m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove "${m.name}"?', style: AppTheme.orbitron(size: 12, color: Colors.white)),
        content: Text('They will no longer appear on About Us.',
            style: AppTheme.inter(size: 12, color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL', style: AppTheme.orbitron(size: 9, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DELETE', style: AppTheme.orbitron(size: 9, color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await TeamService.instance.delete(m.id);
    } catch (e) {
      debugPrint('Team delete failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete. Check your connection.')));
      }
    }
  }
}
