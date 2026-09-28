import 'package:flutter/material.dart';
import '../../../logic/event_status.dart';
import '../../../models/event_item.dart';
import '../../../theme/app_theme.dart';
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
                        EventTypeChip(event: ev),
                        if (ev.statusAt(DateTime.now()) == EventStatus.happeningNow)
                          const HappeningNowBadge(),
                      ]),
                      const SizedBox(height: 6),
                      Text(ev.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 15, weight: FontWeight.w600, height: 1.3)),
                      const SizedBox(height: 4),
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
                SaveEventIconButton(event: ev),
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

/// Green "Happening now" badge, shown while an event is on.
class HappeningNowBadge extends StatelessWidget {
  const HappeningNowBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text('HAPPENING NOW',
              style: AppTheme.inter(size: 9, weight: FontWeight.w700, color: Colors.greenAccent)),
        ]),
      );
}
