import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../models/event_item.dart';
import '../services/event_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../utils/url_utils.dart';
import '../widgets/section_header.dart';
import 'user/event_detail_screen.dart';

class _EventWithDistance {
  final EventItem event;
  final double? distanceKm;
  const _EventWithDistance(this.event, this.distanceKm);
}

/// Events tab — Fandom Conventions list (default) with an additive map view.
class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  bool _showMap = false;
  Position? _fanPosition;
  bool _locationChecked = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    // This tab is built as soon as Home appears (IndexedStack), so don't
    // trigger the OS prompt here — only use location if already granted.
    LocationService.instance.getCurrentPosition(requestIfNeeded: false).then((pos) {
      if (mounted) {
        setState(() {
          _fanPosition = pos;
          _locationChecked = true;
        });
      }
    });
  }

  Future<void> _enableLocation() async {
    setState(() => _locating = true);
    final pos = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _fanPosition = pos;
      _locating = false;
    });
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Location unavailable. Turn on location and allow it for Fandom Verse in Settings.'),
      ));
    }
  }

  Widget _locationBanner() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.near_me_outlined, color: AppTheme.cyan, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Sort conventions by distance from you',
                  style: AppTheme.inter(size: 12, color: Colors.white70)),
            ),
            TextButton(
              onPressed: _locating ? null : _enableLocation,
              child: _locating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan))
                  : Text('USE LOCATION',
                      style: AppTheme.orbitron(size: 9, color: AppTheme.cyan)),
            ),
          ],
        ),
      );

  String _dateLabel(DateTime d) =>
      '${_months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}';

  List<_EventWithDistance> _sortByDistance(List<EventItem> events) {
    // Events with coordinates get a real distance from the Fan's position
    // and sort nearest-first. Events without coordinates (pre-migration)
    // — or when the Fan's position isn't available — fall back to the
    // original date-ordered list with no distance shown, never a fake one.
    final fanPos = _fanPosition;
    if (fanPos == null) {
      return events.map((e) => _EventWithDistance(e, null)).toList();
    }
    final withDistance = <_EventWithDistance>[];
    final withoutDistance = <_EventWithDistance>[];
    for (final e in events) {
      if (e.hasCoordinates) {
        final meters = Geolocator.distanceBetween(
            fanPos.latitude, fanPos.longitude, e.latitude!, e.longitude!);
        withDistance.add(_EventWithDistance(e, meters / 1000));
      } else {
        withoutDistance.add(_EventWithDistance(e, null));
      }
    }
    withDistance.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    return [...withDistance, ...withoutDistance];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionHeader(
                icon: Icons.confirmation_number,
                iconColor: AppTheme.pink,
                title: 'FANDOM CONVENTIONS',
              ),
              _viewToggle(),
            ],
          ),
          const SizedBox(height: 12),
          if (_locationChecked && _fanPosition == null) _locationBanner(),
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

              final sorted = _sortByDistance(events);
              return _showMap ? _mapView(context, sorted) : _listView(context, sorted);
            },
          ),
        ],
      ),
    );
  }

  Widget _viewToggle() => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleButton(Icons.list, !_showMap, () => setState(() => _showMap = false)),
            _toggleButton(Icons.map_outlined, _showMap, () => setState(() => _showMap = true)),
          ],
        ),
      );

  Widget _toggleButton(IconData icon, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.pink.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 16, color: selected ? AppTheme.pink : Colors.grey),
        ),
      );

  Widget _listView(BuildContext context, List<_EventWithDistance> events) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, idx) => _eventCard(context, events[idx]),
      );

  Widget _mapView(BuildContext context, List<_EventWithDistance> events) {
    final withCoords = events.where((e) => e.event.hasCoordinates).toList();
    final center = _fanPosition != null
        ? LatLng(_fanPosition!.latitude, _fanPosition!.longitude)
        : withCoords.isNotEmpty
            ? LatLng(withCoords.first.event.latitude!, withCoords.first.event.longitude!)
            : const LatLng(20, 0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 360,
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: _fanPosition != null ? 11 : 2),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.fandom_verse',
            ),
            MarkerLayer(markers: [
              if (_fanPosition != null)
                Marker(
                  point: LatLng(_fanPosition!.latitude, _fanPosition!.longitude),
                  width: 20,
                  height: 20,
                  child: const Icon(Icons.my_location, color: AppTheme.cyan, size: 20),
                ),
              for (final e in withCoords)
                Marker(
                  point: LatLng(e.event.latitude!, e.event.longitude!),
                  width: 36,
                  height: 36,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EventDetailScreen(event: e.event)),
                    ),
                    child: const Icon(Icons.location_pin, color: AppTheme.pink, size: 36),
                  ),
                ),
            ]),
            RichAttributionWidget(
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventCard(BuildContext context, _EventWithDistance ewd) {
    final ev = ewd.event;
    final price = ev.ticketPrice.isEmpty ? 'Free' : ev.ticketPrice;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev)),
      ),
      child: Container(
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
                      if (ewd.distanceKm != null) ...[
                        const SizedBox(width: 6),
                        Text('• ${ewd.distanceKm!.toStringAsFixed(1)} km away',
                            style: AppTheme.inter(size: 10, color: Colors.grey)),
                      ],
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
                        onPressed: ev.ticketLink.trim().isEmpty
                            ? null
                            : () => launchTicketUrl(context, ev.ticketLink),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppTheme.pink.withValues(alpha: 0.12),
                          side: const BorderSide(color: AppTheme.pink),
                          minimumSize: const Size(80, 26),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Get Tickets',
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
      ),
    );
  }
}
