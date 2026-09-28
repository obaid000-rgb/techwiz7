import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../logic/event_status.dart';
import '../../models/event_item.dart';
import '../../models/event_session.dart';
import '../../theme/app_theme.dart';
import '../../utils/event_format.dart';
import '../../utils/url_utils.dart';
import '../../models/fandom.dart';
import '../../services/fandom_service.dart';
import '../fandoms/fandom_page_screen.dart';
import 'widgets/event_card.dart' show EventTypeChip, HappeningNowBadge;
import 'widgets/save_event_button.dart';
import '../../services/event_service.dart';

/// Event Detail. Normally live: it follows the event document so the
/// interested count and any admin edit show straight away. Opened from My
/// Agenda without internet ([offline]), it shows the saved copy instead:
/// the local cover image, the full agenda, the address as text, and the
/// ticket button reads "Needs internet".
class EventDetailScreen extends StatelessWidget {
  final EventItem event;
  final bool offline;
  final String? localImagePath;
  final Uint8List? localImageBytes;
  final bool noLongerListed;
  const EventDetailScreen({
    super.key,
    required this.event,
    this.offline = false,
    this.localImagePath,
    this.localImageBytes,
    this.noLongerListed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (offline) {
      return _EventDetailBody(
        event: event,
        offline: true,
        localImagePath: localImagePath,
        localImageBytes: localImageBytes,
        noLongerListed: noLongerListed,
      );
    }
    return StreamBuilder<EventItem?>(
      stream: EventService.instance.watchEvent(event.id),
      builder: (context, snap) {
        final live = snap.data;
        return _EventDetailBody(
          event: live ?? event,
          offline: false,
          localImagePath: localImagePath,
          localImageBytes: localImageBytes,
          noLongerListed: noLongerListed ||
              (snap.hasData && (live == null || !live.isPublished)),
        );
      },
    );
  }
}

class _EventDetailBody extends StatelessWidget {
  final EventItem event;
  final bool offline;
  final String? localImagePath;
  final Uint8List? localImageBytes;
  final bool noLongerListed;
  const _EventDetailBody({
    required this.event,
    required this.offline,
    this.localImagePath,
    this.localImageBytes,
    this.noLongerListed = false,
  });

  @override
  Widget build(BuildContext context) {
    final happeningNow = event.statusAt(DateTime.now()) == EventStatus.happeningNow;
    final place = event.venue.isNotEmpty ? '${event.venue}, ${event.city}' : event.city;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.card,
            flexibleSpace: FlexibleSpaceBar(
              background: localImagePath != null && !kIsWeb
                  ? Image.file(File(localImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => Container(color: AppTheme.card))
                  : localImageBytes != null
                  ? Image.memory(localImageBytes!, fit: BoxFit.cover)
                  : event.imageUrl.isNotEmpty && !offline
                  ? Image.network(
                      event.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => Container(color: AppTheme.card),
                    )
                  : Container(
                      color: AppTheme.card,
                      alignment: Alignment.center,
                      child: const Icon(Icons.event, color: Colors.white24, size: 48),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (noLongerListed) ...[
                    const NoLongerListedNote(),
                    const SizedBox(height: 12),
                  ],
                  if (offline) ...[
                    const OfflineCopyNote(text: 'Offline, showing your saved copy'),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (event.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.pink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.category.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      EventTypeChip(event: event),
                      if (happeningNow) const HappeningNowBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (event.fandomIds.isNotEmpty)
                    _EventFandomChips(fandomIds: event.fandomIds),
                  const SizedBox(height: 20),
                  _infoRow(Icons.calendar_today_outlined,
                      formatEventRange(event.date, event.endAt)),
                  const SizedBox(height: 12),
                  _infoRow(Icons.location_on_outlined, place,
                      detail: event.address.isEmpty ? null : event.address),
                  if (event.organizerName.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(Icons.groups_outlined, 'Organized by ${event.organizerName}'),
                  ],
                  if (event.ticketPrice.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(Icons.confirmation_number_outlined, event.ticketPrice),
                  ],
                  const SizedBox(height: 12),
                  _infoRow(Icons.bookmark_border_rounded, interestedLabel(event.interestedCount)),
                  const SizedBox(height: 20),
                  SaveEventButton(event: event),
                  if (event.sessions.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _EventAgenda(sessions: event.sessions),
                  ],
                  const SizedBox(height: 28),
                  _ticketButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {String? detail}) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.cyan, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: AppTheme.inter(size: 13, color: Colors.white70, height: 1.4)),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail,
                      style: AppTheme.inter(size: 12, color: AppTheme.textMuted, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      );

  Widget _ticketButton(BuildContext context) {
    if (offline) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: AppTheme.card,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.wifi_off, color: Colors.grey, size: 18),
          label: Text('Needs internet',
              style: AppTheme.orbitron(size: 12, color: Colors.grey, weight: FontWeight.w800)),
        ),
      );
    }
    if (event.ticketLink.trim().isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: AppTheme.card,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('GET TICKETS',
                  style: AppTheme.orbitron(size: 12, color: Colors.grey, weight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 8),
          Text('Ticket link not available yet.',
              style: AppTheme.inter(size: 11, color: Colors.grey)),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => launchTicketUrl(context, event.ticketLink),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.pink,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text('GET TICKETS',
            style: AppTheme.orbitron(size: 12, color: Colors.white, weight: FontWeight.w800)),
      ),
    );
  }
}

/// "Agenda": sessions grouped under a heading per day ("Tue, Oct 14"), in
/// start-time order, each with its time, title, stage and description.
class _EventAgenda extends StatelessWidget {
  final List<EventSession> sessions;
  const _EventAgenda({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final byDay = <DateTime, List<EventSession>>{};
    for (final s in sortSessions(sessions)) {
      final d = s.startAt;
      byDay.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(s);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Agenda', style: AppTheme.orbitron(size: 14, weight: FontWeight.w700)),
        for (final entry in byDay.entries) ...[
          const SizedBox(height: 14),
          Text(formatAgendaDay(entry.key).toUpperCase(),
              style: AppTheme.inter(size: 11, color: AppTheme.pink, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final s in entry.value) _sessionTile(s),
        ],
      ],
    );
  }

  Widget _sessionTile(EventSession s) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 74,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatEventTime(s.startAt),
                      style: AppTheme.inter(size: 12, color: AppTheme.cyan, weight: FontWeight.w700)),
                  Text(formatEventTime(s.endAt),
                      style: AppTheme.inter(size: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: AppTheme.inter(size: 13, weight: FontWeight.w600)),
                  if (s.stage.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(s.stage, style: AppTheme.inter(size: 11, color: AppTheme.pink)),
                  ],
                  if (s.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(s.description,
                        style: AppTheme.inter(size: 12, color: Colors.white70, height: 1.4)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _EventFandomChips extends StatefulWidget {
  final List<String> fandomIds;
  const _EventFandomChips({required this.fandomIds});

  @override
  State<_EventFandomChips> createState() => _EventFandomChipsState();
}

class _EventFandomChipsState extends State<_EventFandomChips> {
  late final Future<List<Fandom>> _fandoms =
      FandomService.instance.getByIds(widget.fandomIds);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Fandom>>(
        future: _fandoms,
        builder: (context, snap) {
          if (snap.hasError) {
            debugPrint('Event fandoms load error: ${snap.error}');
            return const SizedBox.shrink();
          }
          final byId = {for (final f in snap.data ?? const <Fandom>[]) f.id: f};
          final active = [
            for (final id in widget.fandomIds)
              if (byId[id]?.isActive ?? false) byId[id]!,
          ];
          if (active.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in active) FandomLinkChip(fandomId: f.id, label: f.name),
              ],
            ),
          );
        },
      );
}
