import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event_item.dart';
import '../services/event_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'user/event_detail_screen.dart';

class _EventWithDistance {
  final EventItem event;
  final double? distanceKm;
  const _EventWithDistance(this.event, this.distanceKm);
}

enum _EventView { list, map, calendar }

/// Events tab — Fandom Conventions list (default) with map and calendar views.
/// Only upcoming events are shown; an optional city filter narrows every view.
class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> with WidgetsBindingObserver {
  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  _EventView _view = _EventView.list;
  String? _cityFilter; // null = default GPS "nearby" view
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Position? _fanPosition;
  LocationStatus? _locStatus; // null until the first silent check finishes
  bool _locating = false;
  String? _city;
  bool _cityLookupFailed = false;
  // Subscribed once here and kept in state — NOT via a StreamBuilder in the
  // ListView below. Location results insert/remove header rows above the
  // list, which made the ListView recreate the StreamBuilder; the new
  // subscriber joined Firestore's broadcast stream after the snapshot had
  // already been sent and spun forever.
  StreamSubscription<List<EventItem>>? _eventsSub;
  List<EventItem>? _eventsData;
  Object? _eventsError;

  @override
  void initState() {
    super.initState();
    _eventsSub = EventService.instance.watchUpcomingEvents().listen(
      (events) {
        if (!mounted) return;
        setState(() {
          _eventsData = events;
          _eventsError = null;
        });
      },
      onError: (Object e) {
        debugPrint('Events load error: $e');
        if (mounted) setState(() => _eventsError = e);
      },
    );
    WidgetsBinding.instance.addObserver(this);
    // This tab is built as soon as Home appears (IndexedStack), so don't
    // trigger the OS prompt here — only use location if already granted.
    _locate(request: false);
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from system settings: silently re-check, so enabling GPS
  /// or the app permission takes effect without another tap.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_locating &&
        (_locStatus == LocationStatus.deniedForever ||
            _locStatus == LocationStatus.serviceDisabled)) {
      _locate(request: false);
    }
  }

  Future<void> _locate({required bool request}) async {
    setState(() => _locating = true);
    LocationResult result;
    try {
      result = await LocationService.instance.locate(requestIfNeeded: request);
    } catch (_) {
      result = const LocationResult(LocationStatus.positionUnavailable);
    }
    if (!mounted) return;
    setState(() {
      _locStatus = result.status;
      _fanPosition = result.position;
      _locating = false;
      _city = null;
      _cityLookupFailed = false;
    });
    final pos = result.position;
    if (pos != null) {
      // City name is a label only; if it can't be found the list is
      // unchanged (all events, nearest first) and we say so.
      final city = await LocationService.instance.reverseGeocodeCity(pos.latitude, pos.longitude);
      if (!mounted || _fanPosition != pos) return;
      setState(() {
        _city = city;
        _cityLookupFailed = city == null;
      });
    }
  }

  /// One distinct message + fix per failure state. Every state still shows
  /// the full event list below (the all-cities fallback) — nothing blocks it.
  Widget _locationBanner() {
    final svc = LocationService.instance;
    late final IconData icon;
    late final String text;
    late final String action;
    late final VoidCallback onAction;
    switch (_locStatus!) {
      case LocationStatus.notRequested:
        icon = Icons.near_me_outlined;
        text = 'Turn on location to see the closest events first.';
        action = 'Turn on';
        onAction = () => _locate(request: true);
      case LocationStatus.denied:
        icon = Icons.location_disabled_outlined;
        text = 'Location permission was denied. Showing all events by date.';
        action = 'Try again';
        onAction = () => _locate(request: true);
      case LocationStatus.deniedForever:
        icon = Icons.block;
        text = kIsWeb
            ? 'Location is blocked for this site. Allow it in your browser\'s site settings. Showing all events.'
            : 'Location is blocked for Fandom Verse, so the permission popup can\'t appear again. '
                'Allow it in Settings > Permissions > Location. Showing all events.';
        action = kIsWeb ? 'Retry' : 'Open settings';
        onAction = kIsWeb ? () => _locate(request: true) : () => svc.openAppSettings();
      case LocationStatus.serviceDisabled:
        icon = Icons.gps_off;
        text = 'Your device\'s location (GPS) is turned off. Turn it on to see nearby events. Showing all events.';
        action = kIsWeb ? 'Retry' : 'Turn on GPS';
        onAction = kIsWeb ? () => _locate(request: true) : () => svc.openLocationSettings();
      case LocationStatus.positionUnavailable:
        icon = Icons.location_searching;
        text = 'Couldn\'t get a location fix. Showing all events by date.';
        action = 'Try again';
        onAction = () => _locate(request: true);
      case LocationStatus.granted:
        return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.pink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: AppTheme.inter(size: 13, color: AppTheme.textSecondary, height: 1.4)),
          ),
          TextButton(
            onPressed: _locating ? null : onAction,
            child: _locating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan))
                : Text(action,
                    style: AppTheme.inter(size: 14, weight: FontWeight.w600, color: AppTheme.cyan)),
          ),
        ],
      ),
    );
  }

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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Text('Events', style: AppTheme.orbitron(size: 22, weight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Fan conventions and meetups.',
            style: AppTheme.inter(size: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 20),
        _viewToggle(),
        const SizedBox(height: 16),
        if (_locStatus != null && _fanPosition == null && _cityFilter == null) _locationBanner(),
        if (_fanPosition != null && _cityFilter == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(children: [
              const Icon(Icons.near_me, color: AppTheme.pink, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    _city != null
                        ? 'Near $_city · sorted by distance'
                        : _cityLookupFailed
                            ? 'Couldn\'t determine your city, showing all events by distance'
                            : 'Sorted by distance from you',
                    style: AppTheme.inter(size: 13, color: AppTheme.textSecondary)),
              ),
            ]),
          ),
        Builder(
          builder: (context) {
            if (_eventsError != null && _eventsData == null) {
              return _message(Icons.wifi_off, 'Could not load events',
                  'Check your connection and try again.');
            }
            if (_eventsData == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pink)),
              );
            }
            // Re-check by day here too, so an app left open past midnight
            // drops yesterday's events without waiting for a new snapshot.
            final upcoming = _eventsData!.where((e) => e.isUpcoming).toList();
            final cities = EventService.distinctCities(upcoming);
            // A city that no longer has upcoming events falls back to nearby.
            final filter = _cityFilter != null &&
                    cities.any((c) => c.toLowerCase() == _cityFilter!.toLowerCase())
                ? _cityFilter
                : null;
            final header = _cityFilterRow(context, cities, filter);
            if (upcoming.isEmpty) {
              return _message(Icons.event_outlined, 'No upcoming events',
                  'Check back soon for upcoming conventions.');
            }
            // City chosen: only that city's events, by date (the stream is
            // already date-ordered) — distance from me no longer applies.
            // No city: the default GPS nearby ordering.
            final sorted = filter != null
                ? [
                    for (final e in upcoming)
                      if (e.city.trim().toLowerCase() == filter.toLowerCase())
                        _EventWithDistance(e, null)
                  ]
                : _sortByDistance(upcoming);
            return Column(children: [
              header,
              switch (_view) {
                _EventView.list => _listView(context, sorted),
                _EventView.map => _mapView(context, sorted),
                _EventView.calendar => _calendarView(context, sorted),
              },
            ]);
          },
        ),
      ],
    );
  }

  Widget _message(IconData icon, String title, String subtitle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(icon, color: AppTheme.textMuted, size: 36),
          const SizedBox(height: 10),
          Text(title, style: AppTheme.inter(size: 15, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
        ]),
      );

  Widget _viewToggle() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          _toggleButton(Icons.view_list_rounded, 'List', _view == _EventView.list,
              () => setState(() => _view = _EventView.list)),
          _toggleButton(Icons.map_outlined, 'Map', _view == _EventView.map,
              () => setState(() => _view = _EventView.map)),
          _toggleButton(Icons.calendar_month_outlined, 'Calendar', _view == _EventView.calendar,
              () => setState(() => _view = _EventView.calendar)),
        ]),
      );

  /// City filter: an explicit second way to narrow events, independent of
  /// GPS. Cities come from the upcoming events themselves.
  Widget _cityFilterRow(BuildContext context, List<String> cities, String? filter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Expanded(
          child: Material(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: cities.isEmpty ? null : () => _pickCity(context, cities, filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: filter != null ? AppTheme.cyan : AppTheme.border),
                ),
                child: Row(children: [
                  Icon(Icons.location_city, size: 18, color: filter != null ? AppTheme.cyan : AppTheme.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filter != null ? '$filter · sorted by date' : 'All cities (nearby first)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(
                          size: 13,
                          weight: FontWeight.w600,
                          color: filter != null ? Colors.white : AppTheme.textSecondary),
                    ),
                  ),
                  const Icon(Icons.expand_more, size: 18, color: AppTheme.textMuted),
                ]),
              ),
            ),
          ),
        ),
        if (filter != null)
          TextButton.icon(
            onPressed: () => setState(() => _cityFilter = null),
            icon: const Icon(Icons.near_me, size: 16, color: AppTheme.cyan),
            label: Text('Back to nearby',
                style: AppTheme.inter(size: 12, weight: FontWeight.w600, color: AppTheme.cyan)),
          ),
      ]),
    );
  }

  Future<void> _pickCity(BuildContext context, List<String> cities, String? current) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CityPickerSheet(cities: cities, current: current),
    );
    if (picked == null || !mounted) return;
    setState(() => _cityFilter = picked.isEmpty ? null : picked);
  }

  /// Month grid with a dot on every day that has an upcoming event (after
  /// the city filter). Past months can be browsed but show no events, since
  /// past events are excluded. The tapped day's events list below the grid.
  Widget _calendarView(BuildContext context, List<_EventWithDistance> events) {
    final byDay = <DateTime, List<_EventWithDistance>>{};
    for (final e in events) {
      final d = e.event.date;
      byDay.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(e);
    }
    List<_EventWithDistance> forDay(DateTime d) => byDay[DateTime(d.year, d.month, d.day)] ?? const [];
    final now = DateTime.now();
    final dayEvents = forDay(_selectedDay);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: TableCalendar<_EventWithDistance>(
            firstDay: DateTime(now.year - 1, 1, 1),
            lastDay: DateTime(now.year + 5, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
            eventLoader: forDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            availableGestures: AvailableGestures.horizontalSwipe,
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            }),
            onPageChanged: (focused) => _focusedDay = focused,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: AppTheme.orbitron(size: 13, weight: FontWeight.w700),
              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTheme.inter(size: 11, color: AppTheme.textMuted),
              weekendStyle: AppTheme.inter(size: 11, color: AppTheme.textMuted),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: AppTheme.inter(size: 13, color: Colors.white),
              weekendTextStyle: AppTheme.inter(size: 13, color: Colors.white),
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cyan),
              ),
              todayTextStyle: AppTheme.inter(size: 13, color: AppTheme.cyan, weight: FontWeight.w700),
              selectedDecoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
              selectedTextStyle: AppTheme.inter(size: 13, color: Colors.white, weight: FontWeight.w700),
              markerDecoration: const BoxDecoration(color: AppTheme.pink, shape: BoxShape.circle),
              markersMaxCount: 3,
              markerSize: 5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_months[_selectedDay.month - 1]} ${_selectedDay.day}, ${_selectedDay.year}',
          style: AppTheme.orbitron(size: 12, weight: FontWeight.w700, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        if (dayEvents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(children: [
              const Icon(Icons.event_busy_outlined, color: AppTheme.textMuted, size: 28),
              const SizedBox(height: 8),
              Text('No events on this day', style: AppTheme.inter(size: 14, weight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Days with a pink dot have events.',
                  style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
            ]),
          )
        else
          _listView(context, dayEvents),
      ],
    );
  }

  Widget _toggleButton(IconData icon, String label, bool selected, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 40,
            decoration: BoxDecoration(
              color: selected ? AppTheme.border : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: selected ? Colors.white : AppTheme.textMuted),
              const SizedBox(width: 6),
              // Flexible: three buttons must fit on narrow phones.
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(
                        size: 13, weight: FontWeight.w600, color: selected ? Colors.white : AppTheme.textMuted)),
              ),
            ]),
          ),
        ),
      );

  Widget _listView(BuildContext context, List<_EventWithDistance> events) =>
      Column(children: [for (final e in events) _eventCard(context, e)]);

  Widget _mapView(BuildContext context, List<_EventWithDistance> events) {
    final withCoords = events.where((e) => e.event.hasCoordinates).toList();
    // With a city chosen, centre on that city's events instead of the Fan.
    final cityMode = _cityFilter != null && withCoords.isNotEmpty;
    final center = cityMode
        ? LatLng(withCoords.first.event.latitude!, withCoords.first.event.longitude!)
        : _fanPosition != null
            ? LatLng(_fanPosition!.latitude, _fanPosition!.longitude)
            : withCoords.isNotEmpty
                ? LatLng(withCoords.first.event.latitude!, withCoords.first.event.longitude!)
                : const LatLng(20, 0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 420,
        child: FlutterMap(
          // Rebuilt per filter so the camera moves to the new centre.
          key: ValueKey(_cityFilter),
          options: MapOptions(
              initialCenter: center, initialZoom: cityMode || _fanPosition != null ? 11 : 2),
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
                        if (ewd.distanceKm != null) ...[
                          Text('  ·  ', style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                          Flexible(
                            child: Text(_distanceLabel(ewd.distanceKm!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _distanceLabel(double km) =>
      km < 10 ? '${km.toStringAsFixed(1)} km away' : '${km.round()} km away';
}

/// Searchable list of the cities that have upcoming events. Pops the chosen
/// city, or '' for "All cities (nearby)".
class _CityPickerSheet extends StatefulWidget {
  final List<String> cities;
  final String? current;
  const _CityPickerSheet({required this.cities, required this.current});

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = widget.cities.where((c) => c.toLowerCase().contains(q)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Text('Filter by city', style: AppTheme.orbitron(size: 14, weight: FontWeight.w700)),
            ),
            if (widget.cities.length > 6)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: AppTheme.inter(size: 14, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search cities',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  if (q.isEmpty)
                    ListTile(
                      leading: const Icon(Icons.near_me, color: AppTheme.cyan),
                      title: Text('All cities (nearby first)', style: AppTheme.inter(size: 14)),
                      trailing: widget.current == null
                          ? const Icon(Icons.check, color: AppTheme.cyan)
                          : null,
                      onTap: () => Navigator.pop(context, ''),
                    ),
                  for (final c in shown)
                    ListTile(
                      leading: const Icon(Icons.location_city, color: AppTheme.textMuted),
                      title: Text(c, style: AppTheme.inter(size: 14)),
                      trailing: widget.current?.toLowerCase() == c.toLowerCase()
                          ? const Icon(Icons.check, color: AppTheme.cyan)
                          : null,
                      onTap: () => Navigator.pop(context, c),
                    ),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('No city matches "$_query".',
                          style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
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
