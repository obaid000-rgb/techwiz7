import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../logic/event_status.dart';
import '../../services/auth_service.dart';
import '../../services/saved_event_store.dart';
import '../../theme/app_theme.dart';
import 'event_detail_screen.dart';
import 'widgets/event_card.dart' show EventCard;
import 'widgets/save_event_button.dart' show NoLongerListedNote, OfflineCopyNote;

/// My Agenda: the fan's saved events, read only from the offline copies in
/// Hive, so it works in airplane mode. On open it syncs the copies with the
/// server when there is internet (see [SavedEventStore.sync]).
class MyAgendaScreen extends StatefulWidget {
  const MyAgendaScreen({super.key});

  @override
  State<MyAgendaScreen> createState() => _MyAgendaScreenState();
}

class _MyAgendaScreenState extends State<MyAgendaScreen> {
  ValueListenable<Box>? _box;
  bool _syncing = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    SavedEventStore.instance.listenable().then((l) {
      if (mounted) setState(() => _box = l);
    });
    _sync();
  }

  Future<void> _sync() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final result = await SavedEventStore.instance.sync(user.uid, user.savedEventIds);
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _offline = result == AgendaSyncResult.offline;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: Text('My Agenda', style: AppTheme.orbitron(size: 16, weight: FontWeight.w700)),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.all(18),
              child: SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan)),
            ),
        ],
      ),
      body: user == null || _box == null
          ? const SizedBox.shrink()
          : ValueListenableBuilder<Box>(
              valueListenable: _box!,
              builder: (context, box, _) {
                final entries = [
                  for (final v in box.values)
                    if (v is Map && v['uid'] == user.uid) SavedEventEntry.fromMap(v),
                ];
                return _list(entries);
              },
            ),
    );
  }

  Widget _list(List<SavedEventEntry> entries) {
    final now = DateTime.now();
    final happening = <SavedEventEntry>[];
    final upcoming = <SavedEventEntry>[];
    final past = <SavedEventEntry>[];
    for (final e in entries) {
      switch (e.event.statusAt(now)) {
        case EventStatus.happeningNow:
          happening.add(e);
        case EventStatus.upcoming:
          upcoming.add(e);
        case EventStatus.ended:
          past.add(e);
      }
    }
    int byStart(SavedEventEntry a, SavedEventEntry b) => a.event.date.compareTo(b.event.date);
    happening.sort(byStart);
    upcoming.sort(byStart);
    past.sort((a, b) => byStart(b, a)); // most recent first
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        if (_offline) ...[
          const Align(alignment: Alignment.centerLeft, child: OfflineCopyNote()),
          const SizedBox(height: 12),
        ],
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(children: [
              const Icon(Icons.bookmark_border_rounded, color: AppTheme.textMuted, size: 40),
              const SizedBox(height: 10),
              Text('No saved events yet', style: AppTheme.inter(size: 15, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Tap the bookmark on any event to save it here. Saved events work offline.',
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
            ]),
          ),
        ..._section('HAPPENING NOW', happening),
        ..._section('UPCOMING', upcoming),
        ..._section('PAST', past),
      ],
    );
  }

  List<Widget> _section(String title, List<SavedEventEntry> items) => items.isEmpty
      ? const []
      : [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(title,
                style: AppTheme.orbitron(size: 11, weight: FontWeight.w700, color: AppTheme.textSecondary)),
          ),
          for (final e in items) _tile(e),
        ];

  /// The saved copy's image (works offline); null lets the card use the
  /// network cover or its placeholder.
  ImageProvider? _cover(SavedEventEntry e) {
    if (e.imagePath != null && !kIsWeb) return FileImage(File(e.imagePath!));
    if (e.imageBytes != null) return MemoryImage(e.imageBytes!);
    return null;
  }

  Widget _tile(SavedEventEntry entry) {
    final ev = entry.event;
    return EventCard(
      event: ev,
      coverImage: _cover(entry),
      // Saving/removing stays on Event Detail, as before.
      showSave: false,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(
            event: ev,
            offline: _offline,
            localImagePath: entry.imagePath,
            localImageBytes: entry.imageBytes,
            noLongerListed: entry.noLongerListed,
          ),
        ),
      ),
      footer: ev.sessions.isEmpty && !entry.noLongerListed
          ? null
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (ev.sessions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('${ev.sessions.length} agenda sessions',
                    style: AppTheme.inter(size: 11, color: AppTheme.textMuted)),
              ],
              if (entry.noLongerListed) ...[
                const SizedBox(height: 6),
                const NoLongerListedNote(),
              ],
            ]),
    );
  }
}
