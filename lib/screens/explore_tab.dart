import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/event_item.dart';
import '../models/merchandise.dart';
import '../services/event_service.dart';
import '../services/merchandise_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  String _dateLabel(DateTime d) =>
      '${_months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Conventions header ──────────────────────────────────
          SectionHeader(
            icon: Icons.confirmation_number,
            iconColor: AppTheme.pink,
            title: 'FANDOM CONVENTIONS',
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<EventItem>>(
            stream: EventService.instance.watchEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pink),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.grey, size: 28),
                        const SizedBox(height: 8),
                        Text('Could not load events',
                            style: AppTheme.inter(size: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_outlined, color: Colors.grey, size: 36),
                        const SizedBox(height: 10),
                        Text('No events yet',
                            style: AppTheme.orbitron(
                                size: 12, color: Colors.grey, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Check back soon for upcoming conventions.',
                            style: AppTheme.inter(size: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, idx) => _eventCard(context, events[idx]),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Merchandise header ──────────────────────────────────
          SectionHeader(
            icon: Icons.shopping_bag,
            iconColor: AppTheme.orange,
            title: 'OFFICIAL MERCHANDISE',
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Merchandise>>(
            stream: MerchandiseService.instance.watchMerchandise(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.grey, size: 28),
                        const SizedBox(height: 8),
                        Text('Could not load merchandise',
                            style: AppTheme.inter(size: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              final merch = snapshot.data ?? [];
              if (merch.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 36),
                        const SizedBox(height: 10),
                        Text('No merchandise available',
                            style: AppTheme.orbitron(
                                size: 12, color: Colors.grey, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Official merchandise will appear here when listed.',
                            style: AppTheme.inter(size: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: merch.length,
                itemBuilder: (context, idx) => _merchCard(context, merch[idx]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _eventCard(BuildContext context, EventItem ev) {
    final price = ev.ticketPrice.isEmpty ? 'Free' : ev.ticketPrice;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ev.imageUrl.isNotEmpty
                    ? Image.network(
                        ev.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, st) => Container(
                          width: 80,
                          height: 80,
                          color: AppTheme.bg,
                          alignment: Alignment.center,
                          child: const Icon(Icons.event, color: Colors.white24, size: 28),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppTheme.bg,
                        alignment: Alignment.center,
                        child: const Icon(Icons.event, color: Colors.white24, size: 28),
                      ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                left: 0,
                right: 0,
                child: Text(
                  _dateLabel(ev.date),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    color: AppTheme.cyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ev.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.orbitron(size: 12, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppTheme.cyan, size: 11),
                    const SizedBox(width: 3),
                    Text(ev.city,
                        style: AppTheme.inter(size: 11, color: AppTheme.cyan)),
                  ],
                ),
                Text(ev.venue,
                    style: AppTheme.inter(size: 10, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: AppTheme.orbitron(
                          size: 12, color: AppTheme.cyan, weight: FontWeight.w700),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Pass reserved! Check your email.')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppTheme.pink.withValues(alpha: 0.12),
                        side: const BorderSide(color: AppTheme.pink),
                        minimumSize: const Size(80, 26),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Get Pass',
                          style: AppTheme.orbitron(
                              size: 9,
                              color: AppTheme.pink,
                              weight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _merchCard(BuildContext context, Merchandise item) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => Container(
                        color: AppTheme.bg,
                        alignment: Alignment.center,
                        child: const Icon(Icons.shopping_bag_outlined,
                            color: Colors.white24, size: 36),
                      ),
                    )
                  : Container(
                      color: AppTheme.bg,
                      alignment: Alignment.center,
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: Colors.white24, size: 36),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(
                      size: 12, weight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: AppTheme.orbitron(
                      size: 13, color: AppTheme.orange, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${item.name} added to cart!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      '+ Cart',
                      style: GoogleFonts.orbitron(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
