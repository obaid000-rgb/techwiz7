import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/inquiry_service.dart';
import '../../../theme/app_theme.dart';

/// Admin inbox for Contact Us messages: who sent it, when, and what they
/// wrote. Admin can mark it read / resolved, reply by email, or delete it.
class InquiryManagementScreen extends StatefulWidget {
  const InquiryManagementScreen({super.key});

  @override
  State<InquiryManagementScreen> createState() => _InquiryManagementScreenState();
}

class _InquiryManagementScreenState extends State<InquiryManagementScreen> {
  late final Stream<List<Inquiry>> _inquiries = InquiryService.instance.watchAll();
  String _filter = 'all'; // all | new | read | resolved

  static const _statusColors = {
    'new': AppTheme.pink,
    'read': AppTheme.cyan,
    'resolved': Colors.greenAccent,
  };

  static String _when(DateTime? d) {
    if (d == null) return 'Sending…';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _setStatus(Inquiry q, String status) async {
    try {
      await InquiryService.instance.setStatus(q.id, status);
    } catch (e) {
      debugPrint('Inquiry status update failed: $e');
      _snack('Could not update. Check your connection.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _open(Inquiry q) async {
    if (q.status == 'new') _setStatus(q, 'read');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(q.subject, style: AppTheme.orbitron(size: 13, color: Colors.white)),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('From', q.name),
                _detail('Email', q.email),
                _detail('Sent', _when(q.createdAt)),
                _detail('Account', q.uid == null ? 'Guest (not signed in)' : 'Signed-in fan'),
                const SizedBox(height: 10),
                Text('MESSAGE', style: AppTheme.inter(size: 10, color: Colors.grey, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                SelectableText(q.message, style: AppTheme.inter(size: 13, color: Colors.white, height: 1.5)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final uri = Uri(
                scheme: 'mailto',
                path: q.email,
                queryParameters: {'subject': 'Re: ${q.subject}'},
              );
              if (!await launchUrl(uri)) _snack('No email app found.');
            },
            icon: const Icon(Icons.reply, size: 16, color: AppTheme.cyan),
            label: Text('REPLY', style: AppTheme.orbitron(size: 9, color: AppTheme.cyan)),
          ),
          if (q.status != 'resolved')
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _setStatus(q, 'resolved');
              },
              child: Text('MARK RESOLVED', style: AppTheme.orbitron(size: 9, color: Colors.greenAccent)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CLOSE', style: AppTheme.orbitron(size: 9, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 70,
            child: Text(label, style: AppTheme.inter(size: 12, color: Colors.grey)),
          ),
          Expanded(child: SelectableText(value, style: AppTheme.inter(size: 12, color: Colors.white))),
        ]),
      );

  Future<void> _delete(Inquiry q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Delete this message?', style: AppTheme.orbitron(size: 12, color: Colors.white)),
        content: Text('From ${q.name}: "${q.subject}". This cannot be undone.',
            style: AppTheme.inter(size: 12, color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('CANCEL', style: AppTheme.orbitron(size: 9, color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('DELETE', style: AppTheme.orbitron(size: 9, color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await InquiryService.instance.delete(q.id);
    } catch (e) {
      debugPrint('Inquiry delete failed: $e');
      _snack('Could not delete. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Inquiry>>(
      stream: _inquiries,
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('Inquiries load error: ${snap.error}');
          return Center(
            child: Text('Could not load messages. Check your connection.',
                style: AppTheme.inter(size: 12, color: Colors.redAccent)),
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.cyan));
        final all = snap.data!;
        final newCount = all.where((q) => q.status == 'new').length;
        final shown = _filter == 'all' ? all : all.where((q) => q.status == _filter).toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Text('Inquiries', style: AppTheme.orbitron(size: 13)),
              const SizedBox(width: 8),
              if (newCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.pink, borderRadius: BorderRadius.circular(10)),
                  child: Text('$newCount new', style: AppTheme.inter(size: 11, weight: FontWeight.w700)),
                ),
            ]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              for (final f in const ['all', 'new', 'read', 'resolved'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(f[0].toUpperCase() + f.substring(1)),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    showCheckmark: false,
                    selectedColor: AppTheme.accent,
                    backgroundColor: AppTheme.card,
                    labelStyle: AppTheme.inter(size: 12, color: Colors.white),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(all.isEmpty ? 'No messages yet.' : 'Nothing here.',
                        style: AppTheme.inter(size: 13, color: Colors.grey)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _row(shown[i]),
                  ),
          ),
        ]);
      },
    );
  }

  Widget _row(Inquiry q) {
    final color = _statusColors[q.status] ?? Colors.grey;
    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(q),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: q.status == 'new' ? AppTheme.pink.withValues(alpha: 0.6) : AppTheme.border),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(q.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(
                            size: 13, weight: q.status == 'new' ? FontWeight.w700 : FontWeight.w500)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Text(q.status.toUpperCase(),
                        style: AppTheme.inter(size: 9, color: color, weight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 3),
                Text('${q.name} · ${q.email}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
                Text(_when(q.createdAt), style: AppTheme.inter(size: 10, color: Colors.grey)),
              ]),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              onPressed: () => _delete(q),
            ),
          ]),
        ),
      ),
    );
  }
}
