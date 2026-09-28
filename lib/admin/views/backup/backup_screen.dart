import 'package:flutter/material.dart';
import '../../../services/backup_service.dart';
import '../../../theme/app_theme.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late final Stream<List<BackupRecord>> _history = BackupService.instance.watchHistory();
  bool _exporting = false;
  BackupResult? _last;
  String? _error;

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      final result = await BackupService.instance.exportAll();
      if (mounted) setState(() => _last = result);
    } catch (e) {
      debugPrint('Backup export failed: $e');
      if (mounted) setState(() => _error = 'Export failed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  static String _size(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1024 * 1024
          ? '${(bytes / 1024).toStringAsFixed(1)} KB'
          : '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';

  static String _when(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Backup & Export', style: AppTheme.orbitron(size: 13)),
        const SizedBox(height: 6),
        Text('Downloads every collection the app uses as one JSON file, then opens the share '
            'sheet so you can save it to Drive, Files or email.',
            style: AppTheme.inter(size: 12, color: Colors.grey, height: 1.4)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _exporting ? null : _export,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _exporting
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.cloud_download_outlined),
            label: Text(_exporting ? 'EXPORTING…' : 'EXPORT ALL DATA',
                style: AppTheme.orbitron(size: 11, color: Colors.black, weight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.orange.withValues(alpha: 0.4)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, size: 16, color: AppTheme.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Firebase Auth accounts are not included. Production would use Firestore scheduled backups.',
                  style: AppTheme.inter(size: 12, color: Colors.white70, height: 1.4)),
            ),
          ]),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: AppTheme.inter(size: 12, color: Colors.redAccent)),
        ],
        if (_last != null) ...[
          const SizedBox(height: 12),
          _resultCard(_last!),
        ],
        const SizedBox(height: 22),
        Text('PAST BACKUPS', style: AppTheme.orbitron(size: 10, color: Colors.grey, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        StreamBuilder<List<BackupRecord>>(
          stream: _history,
          builder: (context, snap) {
            if (snap.hasError) {
              debugPrint('Backup history error: ${snap.error}');
              return Text('Could not load backup history.',
                  style: AppTheme.inter(size: 12, color: Colors.redAccent));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.cyan));
            }
            final list = snap.data!;
            if (list.isEmpty) {
              return Text('No backups yet.', style: AppTheme.inter(size: 12, color: Colors.grey));
            }
            return Column(children: [for (final b in list) _historyRow(b)]);
          },
        ),
      ],
    );
  }

  Widget _resultCard(BackupResult r) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: r.warnings.isEmpty ? Colors.greenAccent : AppTheme.orange),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Exported ${r.fileName} (${_size(r.fileSizeBytes)})',
              style: AppTheme.inter(size: 12, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(r.counts.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
              style: AppTheme.inter(size: 11, color: Colors.grey)),
          if (r.warnings.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Not included:', style: AppTheme.inter(size: 11, color: AppTheme.orange, weight: FontWeight.w700)),
            for (final w in r.warnings) Text('• $w', style: AppTheme.inter(size: 11, color: AppTheme.orange)),
          ],
        ]),
      );

  Widget _historyRow(BackupRecord b) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          const Icon(Icons.inventory_2_outlined, color: AppTheme.cyan, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_when(b.exportedAt), style: AppTheme.inter(size: 13, weight: FontWeight.w600)),
              Text('${b.adminEmail} · ${b.totalDocs} documents · ${_size(b.fileSizeBytes)}'
                  '${b.warnings.isEmpty ? '' : ' · ${b.warnings.length} skipped'}',
                  style: AppTheme.inter(size: 11, color: Colors.grey)),
            ]),
          ),
        ]),
      );
}
