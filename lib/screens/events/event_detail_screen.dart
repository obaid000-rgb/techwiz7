import 'package:flutter/material.dart';
import '../../models/event_item.dart';
import '../../theme/app_theme.dart';
import '../../utils/url_utils.dart';

class EventDetailScreen extends StatelessWidget {
  final EventItem event;
  const EventDetailScreen({super.key, required this.event});

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _dateLabel(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.card,
            flexibleSpace: FlexibleSpaceBar(
              background: event.imageUrl.isNotEmpty
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
                  if (event.category.isNotEmpty) ...[
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
                    const SizedBox(height: 12),
                  ],
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  _infoRow(Icons.calendar_today_outlined, _dateLabel(event.date)),
                  const SizedBox(height: 12),
                  _infoRow(Icons.location_on_outlined,
                      event.venue.isNotEmpty ? '${event.venue}, ${event.city}' : event.city),
                  if (event.ticketPrice.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(Icons.confirmation_number_outlined, event.ticketPrice),
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

  Widget _infoRow(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.cyan, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTheme.inter(size: 13, color: Colors.white70, height: 1.4)),
          ),
        ],
      );

  Widget _ticketButton(BuildContext context) {
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
