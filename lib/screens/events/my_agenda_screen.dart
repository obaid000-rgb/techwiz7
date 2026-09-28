import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../logic/event_status.dart';
import '../../services/auth_service.dart';
import '../../services/saved_event_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/event_format.dart';
import 'event_detail_screen.dart';
import 'widgets/event_card.dart' show EventTypeChip, HappeningNowBadge;
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

  Widget _cover(SavedEventEntry e) {
    Widget fallback() => Container(
          color: AppTheme.bg,
          alignment: Alignment.center,
          child: Icon(e.event.eventType.icon, color: e.event.eventType.color),
        );
    if (e.imagePath != null && !kIsWeb) {
      return Image.file(File(e.imagePath!), fit: BoxFit.cover, errorBuilder: (c, x, s) => fallback());
    }
    if (e.imageBytes != null) return Image.memory(e.imageBytes!, fit: BoxFit.cover);
    return fallback();
  }

  Widget _tile(SavedEventEntry entry) {
    final ev = entry.event;
    final happening = ev.statusAt(DateTime.now()) == EventStatus.happeningNow;
    final place = [ev.venue, ev.city].where((x) => x.trim().isNotEmpty).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(width: 72, height: 72, child: _cover(entry)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        EventTypeChip(event: ev),
                        if (happening) const HappeningNowBadge(),
                      ]),
                      const SizedBox(height: 6),
                      Text(ev.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 14, weight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(formatEventRange(ev.date, ev.endAt),
                          style: AppTheme.inter(size: 12, color: AppTheme.cyan)),
                      if (place.isNotEmpty)
                        Text(place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
                      if (ev.sessions.isNotEmpty)
                        Text('${ev.sessions.length} agenda sessions',
                            style: AppTheme.inter(size: 11, color: AppTheme.textMuted)),
                      if (entry.noLongerListed) ...[
                        const SizedBox(height: 6),
                        const NoLongerListedNote(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
