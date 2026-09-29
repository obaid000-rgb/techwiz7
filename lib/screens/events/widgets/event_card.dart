import 'package:flutter/material.dart';
import '../../../logic/event_query.dart';
import '../../../logic/event_status.dart';
import '../../../models/event_item.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/event_format.dart';
import '../event_detail_screen.dart';
import 'save_event_button.dart';

/// The one event card, used everywhere events appear: the Events tab,
/// Home's Trending Events, a fandom's Events tab and My Agenda.
///
/// A 16:9 cover with a dark bottom gradient, a date badge, the type chip,
/// "Happening now" while the event runs and the save icon; below it the
/// title, city and venue, distance (when known), price and interested
/// count. Events without a cover get a designed placeholder (brand
/// gradient + the type's icon), never a blank or broken image.
///
/// [compact] is the narrower version for horizontal rows.
class EventCard extends StatelessWidget {
  final EventItem event;
  final double? distanceKm;
  final bool compact;
  /// My Agenda: the saved copy's local image instead of the network one.
  final ImageProvider? coverImage;
  /// Replaces the default "open Event Detail" tap (My Agenda passes its
  /// offline details).
  final VoidCallback? onTap;
  final bool showSave;
  /// Extra lines under the details (My Agenda: sessions, "no longer listed").
  final Widget? footer;

  const EventCard({
    super.key,
    required this.event,
    this.distanceKm,
    this.compact = false,
    this.coverImage,
    this.onTap,
    this.showSave = true,
    this.footer,
  });

  /// Width of a [compact] card in a horizontal row, and the row's height.
  static const double compactWidth = 250;
  static const double compactRowHeight = 262;

  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  static String distanceLabel(double km) =>
      km < 10 ? '${km.toStringAsFixed(1)} km away' : '${km.round()} km away';

  @override
  Widget build(BuildContext context) {
    final ev = event;
    final now = DateTime.now();
    final live = ev.statusAt(now) == EventStatus.happeningNow;
    final card = Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ??
            () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev)),
                ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: live ? Colors.greenAccent.withValues(alpha: 0.5) : AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: _cover(live, now)),
              // Compact cards have a fixed height; a very large font size
              // clips the last line instead of overflowing.
              compact
                  ? Expanded(
                      child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(), child: _details()))
                  : _details(),
            ],
          ),
        ),
      ),
    );
    if (compact) {
      return SizedBox(width: compactWidth, height: compactRowHeight, child: card);
    }
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: card);
  }

  Widget _cover(bool live, DateTime now) {
    final url = ev.imageUrl.trim();
    final Widget image = coverImage != null
        ? Image(image: coverImage!, fit: BoxFit.cover, errorBuilder: (c, e, s) => _placeholder())
        : url.isEmpty
            ? _placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => _placeholder(),
                loadingBuilder: (c, child, progress) => progress == null ? child : _placeholder(),
              );
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        // Dark gradient at the bottom so the chips stay readable on any cover.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.45, 1],
              colors: [Colors.transparent, Color(0xDD000000)],
            ),
          ),
        ),
        Positioned(top: 10, left: 10, child: _dateBadge()),
        if (showSave && ev.statusAt(now) != EventStatus.ended)
          Positioned(
            top: 6,
            right: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
              child: SaveEventIconButton(event: ev),
            ),
          ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: Wrap(spacing: 6, runSpacing: 4, children: [
            EventTypeChip(event: ev, onImage: true),
            if (live) EventStatusBadge(event: ev),
          ]),
        ),
      ],
    );
  }

  EventItem get ev => event;

  /// No cover: brand gradient tinted by the event type, with its icon.
  Widget _placeholder() {
    final t = ev.eventType;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accent, Color.lerp(AppTheme.pink, t.color, 0.5)!, AppTheme.cyan.withValues(alpha: 0.8)],
        ),
      ),
      child: Center(
        child: Icon(t.icon, size: compact ? 44 : 56, color: Colors.white.withValues(alpha: 0.85)),
      ),
    );
  }

  Widget _dateBadge() => Container(
        width: compact ? 44 : 50,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${ev.date.day}',
              style: AppTheme.orbitron(size: compact ? 16 : 19, weight: FontWeight.w800, color: Colors.white)),
          Text(_months[ev.date.month - 1],
              style: AppTheme.inter(size: 10, weight: FontWeight.w700, color: AppTheme.pink)),
        ]),
      );

  Widget _details() {
    final price = ev.ticketPrice.isEmpty ? 'Free' : ev.ticketPrice;
    final place = [displayCity(ev.city), ev.venue.trim()].where((x) => x.isNotEmpty).join(' · ');
    final small = compact ? 11.0 : 12.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 10, 12, compact ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(ev.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.inter(size: compact ? 14 : 16, weight: FontWeight.w700, height: 1.25)),
          const SizedBox(height: 4),
          Text(formatEventRange(ev.date, ev.endAt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.inter(size: small, weight: FontWeight.w600, color: Colors.white70)),
          if (place.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.place_outlined, size: small + 2, color: AppTheme.textMuted),
              const SizedBox(width: 3),
              Expanded(
                child: Text(place,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(size: small, color: AppTheme.textSecondary)),
              ),
            ]),
          ],
          const SizedBox(height: 6),
          Row(children: [
            Flexible(
              child: Text(price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(size: small, weight: FontWeight.w700, color: AppTheme.cyan)),
            ),
            if (distanceKm != null) ...[
              Text('  ·  ', style: AppTheme.inter(size: small, color: AppTheme.textMuted)),
              Flexible(
                child: Text(distanceLabel(distanceKm!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(size: small, color: AppTheme.textMuted)),
              ),
            ],
            if (ev.interestedCount > 0) ...[
              Text('  ·  ', style: AppTheme.inter(size: small, color: AppTheme.textMuted)),
              Flexible(
                child: Text(interestedLabel(ev.interestedCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(size: small, color: AppTheme.textMuted)),
              ),
            ],
          ]),
          ?footer,
        ],
      ),
    );
  }
}

/// Small chip with the event's type icon and label ("Convention", …).
class EventTypeChip extends StatelessWidget {
  final EventItem event;
  /// On a cover image: a dark backing so it reads on any photo.
  final bool onImage;
  const EventTypeChip({super.key, required this.event, this.onImage = false});

  @override
  Widget build(BuildContext context) {
    final t = event.eventType;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: onImage ? Colors.black.withValues(alpha: 0.6) : t.color.withValues(alpha: 0.14),
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
