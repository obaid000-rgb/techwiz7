import 'package:flutter/material.dart';
import '../../../logic/event_status.dart';
import '../../../models/event_item.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/event_format.dart';
import '../event_detail_screen.dart';
import 'save_event_button.dart';

/// Event list card (date tile, title, place, price, optional distance).
/// Used by the Events tab, Home's Trending Events and a fandom's Events tab;
/// tap opens Event Detail. Shows the event type, plus "Happening now" while
/// the event is on.
class EventCard extends StatelessWidget {
  final EventItem event;
  final double? distanceKm;
  const EventCard({super.key, required this.event, this.distanceKm});

  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final ev = event;
    final price = ev.ticketPrice.isEmpty ? 'Free' : ev.ticketPrice;
    final place = [ev.venue, ev.city].where((x) => x.trim().isNotEmpty).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev)),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 66,
                  decoration: BoxDecoration(
                    color: AppTheme.pink.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.pink.withValues(alpha: 0.4)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_months[ev.date.month - 1],
                        style: AppTheme.inter(size: 11, weight: FontWeight.w700, color: AppTheme.pink)),
                    Text('${ev.date.day}', style: AppTheme.orbitron(size: 22, weight: FontWeight.w800)),
                  ]),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        EventStatusBadge(event: ev),
                        EventTypeChip(event: ev),
                      ]),
                      const SizedBox(height: 6),
                      Text(ev.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 15, weight: FontWeight.w600, height: 1.3)),
                      const SizedBox(height: 4),
                      Text(formatEventRange(ev.date, ev.endAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 12, weight: FontWeight.w600, color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Flexible(
                          child: Text(price,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.inter(size: 12, weight: FontWeight.w600, color: AppTheme.cyan)),
                        ),
                        if (distanceKm != null) ...[
                          Text('  ·  ', style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                          Flexible(
                            child: Text(_distanceLabel(distanceKm!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                          ),
                        ],
                      ]),
                      if (ev.interestedCount > 0) ...[
                        const SizedBox(height: 4),
                        Text(interestedLabel(ev.interestedCount),
                            style: AppTheme.inter(size: 11, color: AppTheme.textMuted)),
                      ],
                    ],
                  ),
                ),
                if (ev.statusAt(DateTime.now()) != EventStatus.ended) SaveEventIconButton(event: ev),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _distanceLabel(double km) =>
      km < 10 ? '${km.toStringAsFixed(1)} km away' : '${km.round()} km away';
}

/// Small chip with the event's type icon and label ("Convention", …).
class EventTypeChip extends StatelessWidget {
  final EventItem event;
  const EventTypeChip({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final t = event.eventType;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: t.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: t.color.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(t.icon, color: t.color, size: 11),
        const SizedBox(width: 4),
        Text(t.label.toUpperCase(),
            style: AppTheme.inter(size: 9, weight: FontWeight.w700, color: t.color)),
      ]),
    );
  }
}

/// Status badge worked out from the current time every time it builds:
/// COMING SOON (cyan) before the start, NOW (green, with a live dot and
/// "LIVE") while the event runs, CLOSED (grey) once it has ended.
class EventStatusBadge extends StatelessWidget {
  final EventItem event;
  final bool large;
  const EventStatusBadge({super.key, required this.event, this.large = false});

  @override
  Widget build(BuildContext context) {
    final status = event.statusAt(DateTime.now());
    final color = switch (status) {
      EventStatus.upcoming => AppTheme.cyan,
      EventStatus.happeningNow => Colors.greenAccent,
      EventStatus.ended => Colors.grey,
    };
    final label = status == EventStatus.happeningNow ? 'NOW · LIVE' : eventStatusLabel(status);
    final font = large ? 11.0 : 9.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 10 : 7, vertical: large ? 4 : 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: status == EventStatus.happeningNow ? 0.2 : 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        boxShadow: status == EventStatus.happeningNow
            ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10)]
            : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (status == EventStatus.happeningNow) ...[
          Container(
            width: font * 0.7,
            height: font * 0.7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
        ] else ...[
          Icon(status == EventStatus.upcoming ? Icons.schedule_rounded : Icons.lock_clock_outlined,
              size: font + 2, color: color),
          const SizedBox(width: 3),
        ],
        Text(label, style: AppTheme.inter(size: font, weight: FontWeight.w800, color: color)),
      ]),
    );
  }
}
