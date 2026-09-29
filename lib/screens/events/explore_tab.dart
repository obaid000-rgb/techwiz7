import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../logic/event_query.dart';
import '../../logic/event_status.dart';
import '../../models/event_item.dart';
import '../../models/event_type.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import 'event_detail_screen.dart';
import 'my_agenda_screen.dart';
import '../shop/shop_tab.dart' show showGuestLoginSheet;
import 'widgets/event_card.dart';
import 'widgets/event_filter_bar.dart';

enum _EventView { list, map, calendar }

/// Events tab — Fandom Conventions list (default) with map and calendar views.
/// Only events that haven't ended are shown; the toolbar filters (search,
/// type, date, distance, city, My fandoms) narrow all three views alike.
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
  EventFilter _filter = EventFilter.none;
  final TextEditingController _searchCtr = TextEditingController();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  DateTime _calendarToday = DateTime.now(); // the day the calendar was last reset to
  Position? _fanPosition;
  LocationStatus? _locStatus; // null until the first silent check finishes
  bool _locating = false;
  String? _city;
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
    _searchCtr.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from system settings: silently re-check, so enabling GPS
  /// or the app permission takes effect without another tap.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The Events tab lives for the whole app session, so the calendar's
    // "today" was fixed at launch; after midnight it opened on yesterday.
    // Move the calendar to the real today when the app comes back on a new day.
    if (state == AppLifecycleState.resumed && !isSameDay(_calendarToday, DateTime.now())) {
      final now = DateTime.now();
      setState(() {
        _calendarToday = now;
        _focusedDay = now;
        _selectedDay = now;
      });
    }
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
    });
    final pos = result.position;
    if (pos != null) {
      // City name is a label only; if it can't be found the list is
      // unchanged (all events, nearest first) and we say so.
      final city = await LocationService.instance.reverseGeocodeCity(pos.latitude, pos.longitude);
      if (!mounted || _fanPosition != pos) return;
      setState(() {
        _city = city;

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
        text = 'Turn on location to see events near you';
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

  GeoPoint? get _userLocation {
    final p = _fanPosition;
    return p == null ? null : (lat: p.latitude, lng: p.longitude);
  }

  void _clearAll() {
    _searchCtr.clear();
    setState(() => _filter = EventFilter.none);
  }

  /// Buttons beside the tab title.
  List<Widget> headerActions(BuildContext context) => [
        IconButton(
          tooltip: 'My Agenda',
          icon: const Icon(Icons.event_note_rounded, color: AppTheme.pink),
          onPressed: () {
            if (AuthService.instance.currentUser == null) {
              showGuestLoginSheet(context, feature: 'My Agenda');
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAgendaScreen()));
          },
        ),
      ];

  /// Top of the tab: title plus the "My Agenda" entry point.
  Widget _header() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Events', style: AppTheme.orbitron(size: 22, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Fan conventions and meetups.',
                  style: AppTheme.inter(size: 14, color: AppTheme.textSecondary)),
            ]),
          ),
          ...headerActions(context),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserData?>(
      valueListenable: AuthService.instance.userNotifier,
      builder: (context, user, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          _header(),
          const SizedBox(height: 20),
          _viewToggle(),
          const SizedBox(height: 16),
          // List view shows this card in place of the "Near you" row; Map
          // and Calendar keep it on top so location can be turned on there.
          if (_view != _EventView.list && _locStatus != null && _fanPosition == null) _locationBanner(),
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
              // Re-check here too, so an app left open drops an event once it
              // ends (its end time, or the end of its start day) without
              // waiting for a new snapshot. A multi-day convention stays until
              // its last day is over.
              final now = DateTime.now();
              final visible = _eventsData!.where((e) => e.isVisibleToFans(now)).toList();
              if (visible.isEmpty) {
                return _message(Icons.event_outlined, 'No upcoming events',
                    'Check back soon for upcoming conventions.');
              }
              final cities = availableCities(visible, now);
              final location = _userLocation;
              // The filter that actually applies: a chosen city that no longer
              // has events is dropped, radius needs a location, and "My
              // fandoms" needs an account.
              //
              // No default filter: the tab opens on EventFilter.none, and
              // the detected location never becomes a city or radius
              // filter. It only feeds the "Near you" row and the distances
              // on cards; only a fan's own choices narrow the list.
              final effective = _filter.copyWith(
                cities: {
                  for (final c in _filter.cities)
                    if (cities.any((x) => normalizeCity(x) == normalizeCity(c))) c,
                },
                clearRadius: location == null,
                myFandomsOnly: user != null && _filter.myFandomsOnly,
              );
              // One filter drives List, Map and Calendar alike.
              final matches = applyEventFilter(
                  visible, effective, location, user?.followedFandomIds ?? const [], now);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EventFilterBar(
                    filter: effective,
                    searchController: _searchCtr,
                    cities: cities,
                    hasLocation: location != null,
                    signedIn: user != null,
                    onChanged: (f) => setState(() => _filter = f),
                    onClearAll: _clearAll,
                  ),
                  const SizedBox(height: 14),
                  if (matches.isEmpty)
                    _noMatches(effective)
                  else
                    switch (_view) {
                      // Rows ("Near you", "Happening now") only while no
                      // filter is on; a filtered list is shown on its own.
                      _EventView.list => effective.isEmpty
                          ? _browseView(context, matches, now)
                          : _listView(context, matches),
                      _EventView.map => _mapView(context, matches),
                      _EventView.calendar => _calendarView(context, matches),
                    },
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Nothing matches: say which filters are on and offer Clear all.
  Widget _noMatches(EventFilter filter) {
    final active = describeEventFilter(filter);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(children: [
        const Icon(Icons.filter_alt_off_outlined, color: AppTheme.textMuted, size: 36),
        const SizedBox(height: 10),
        Text('No events match your filters', style: AppTheme.inter(size: 15, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(active.join(' · '),
            textAlign: TextAlign.center,
            style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _clearAll,
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.cyan)),
          icon: const Icon(Icons.clear_all, size: 18, color: AppTheme.cyan),
          label: Text('Clear all', style: AppTheme.inter(size: 13, weight: FontWeight.w600, color: AppTheme.cyan)),
        ),
      ]),
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

  /// Month grid with a dot on every day that has an upcoming event (after
  /// all filters). Past months can be browsed but show no events, since
  /// ended events are excluded. The tapped day's events list below the grid.
  /// A multi-day event is marked on every day it runs (capped at 60 days).
  Widget _calendarView(BuildContext context, List<EventMatch> events) {
    final byDay = <DateTime, List<EventMatch>>{};
    for (final e in events) {
      final start = e.event.date;
      // Last day the event runs; an end at exactly midnight belongs to the
      // day before.
      final last = e.event.effectiveEnd.subtract(const Duration(microseconds: 1));
      var day = DateTime(start.year, start.month, start.day);
      for (var i = 0; i < 60 && (i == 0 || !day.isAfter(last)); i++) {
        byDay.putIfAbsent(day, () => []).add(e);
        day = DateTime(day.year, day.month, day.day + 1);
      }
    }
    List<EventMatch> forDay(DateTime d) => byDay[DateTime(d.year, d.month, d.day)] ?? const [];
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
          child: TableCalendar<EventMatch>(
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
            onPageChanged: (focused) => setState(() => _focusedDay = focused),
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
            // table_calendar draws "selected" instead of "today" when a day is
            // both — and today starts selected — so today lost its marking.
            // Keep today's cyan ring on top of the selected fill.
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, day, focused) {
                if (!isSameDay(day, now)) return null; // default selected look
                return Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.cyan, width: 2),
                    ),
                    child: Text('${day.day}',
                        style: AppTheme.inter(size: 13, color: Colors.white, weight: FontWeight.w800)),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: Text(
              '${isSameDay(_selectedDay, now) ? 'TODAY · ' : ''}'
              '${_months[_selectedDay.month - 1]} ${_selectedDay.day}, ${_selectedDay.year}',
              style: AppTheme.orbitron(size: 12, weight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
          ),
          if (!isSameDay(_selectedDay, now) || _focusedDay.year != now.year || _focusedDay.month != now.month)
            TextButton.icon(
              onPressed: () => setState(() {
                _focusedDay = now;
                _selectedDay = now;
              }),
              icon: const Icon(Icons.today_outlined, size: 16, color: AppTheme.cyan),
              label: Text('Today', style: AppTheme.inter(size: 12, weight: FontWeight.w600, color: AppTheme.cyan)),
            ),
        ]),
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

  Widget _listView(BuildContext context, List<EventMatch> events) =>
      Column(children: [for (final e in events) _eventCard(context, e)]);

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// The unfiltered List view: "Near you" (or the turn-on-location card),
  /// "Happening now", then every upcoming event from every city.
  Widget _browseView(BuildContext context, List<EventMatch> all, DateTime now) {
    // "Near you" rule: within kNearYouKm (50 km) of the fan, or in the city
    // their location resolves to; nearest first. Needs a location fix.
    final near = _fanPosition == null ? const <EventMatch>[] : nearYouEvents(all, _city);
    final happening = [
      for (final m in soonestFirst(all))
        if (m.event.statusAt(now) == EventStatus.happeningNow) m,
    ];
    final upcoming = soonestFirst(all);
    final children = <Widget>[];

    if (_fanPosition == null) {
      if (_locStatus != null) children.add(_locationBanner());
    } else if (near.isNotEmpty) {
      children
        ..add(_sectionTitle('NEAR YOU',
            _city != null ? 'In ${displayCity(_city!)} or within ${kNearYouKm.round()} km' : 'Within ${kNearYouKm.round()} km of you'))
        ..add(_row(near))
        ..add(const SizedBox(height: 22));
    }
    if (happening.isNotEmpty) {
      children
        ..add(_sectionTitle('HAPPENING NOW', 'On right now'))
        ..add(_row(happening))
        ..add(const SizedBox(height: 22));
    }
    children.add(_sectionTitle('ALL UPCOMING EVENTS', 'Every city, soonest first'));
    String? month;
    for (final m in upcoming) {
      final label = '${_monthNames[m.event.date.month - 1]} ${m.event.date.year}';
      if (label != month) {
        month = label;
        children.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Text(label, style: AppTheme.inter(size: 14, weight: FontWeight.w700, color: AppTheme.pink)),
        ));
      }
      children.add(_eventCard(context, m));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _sectionTitle(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTheme.orbitron(size: 13, weight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
        ]),
      );

  /// A horizontal row of compact cards.
  Widget _row(List<EventMatch> items) => SizedBox(
        height: EventCard.compactRowHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) => EventCard(
            key: ValueKey('row-${items[i].event.id}'),
            event: items[i].event,
            distanceKm: items[i].distanceKm,
            compact: true,
          ),
        ),
      );

  Widget _mapView(BuildContext context, List<EventMatch> events) {
    final withCoords = events.where((e) => e.event.hasCoordinates).toList();
    final points = [for (final e in withCoords) LatLng(e.event.latitude!, e.event.longitude!)];
    // Camera: with a city chosen, fit that city's results. Otherwise centre
    // on the fan when known, zoomed out just enough to show every marker;
    // without a location, fit all markers.
    final cityMode = _filter.cities.isNotEmpty && points.isNotEmpty;
    final fan = _fanPosition == null ? null : LatLng(_fanPosition!.latitude, _fanPosition!.longitude);
    final MapOptions options;
    if (!cityMode && fan != null) {
      var farthestKm = 0.0;
      for (final p in points) {
        farthestKm = math.max(farthestKm, haversineKm(fan.latitude, fan.longitude, p.latitude, p.longitude));
      }
      // Web-Mercator metres per pixel at zoom z = 156543 · cos(lat) / 2^z;
      // pick the zoom where the farthest marker is ~150 px from the centre.
      final zoom = farthestKm < 1
          ? 11.0
          : (math.log(156543 * math.cos(fan.latitude * math.pi / 180) * 150 / (farthestKm * 1000)) / math.ln2)
              .clamp(2.0, 11.0);
      options = MapOptions(initialCenter: fan, initialZoom: zoom);
    } else if (points.length > 1) {
      options = MapOptions(
        initialCameraFit: CameraFit.coordinates(
            coordinates: points, padding: const EdgeInsets.all(48), maxZoom: 12),
      );
    } else {
      options = MapOptions(
          initialCenter: points.isNotEmpty ? points.first : const LatLng(20, 0),
          initialZoom: points.isNotEmpty ? 11 : 2);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 420,
            child: FlutterMap(
              // Rebuilt when the filtered set changes so the camera moves to
              // the new centre.
              key: ValueKey(withCoords.map((e) => e.event.id).join(',')),
              options: options,
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
                  // Each pin takes its event type's colour (see the legend).
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
                        child: Icon(Icons.location_pin, color: e.event.eventType.color, size: 36),
                      ),
                    ),
                ]),
                RichAttributionWidget(
                  attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 14, runSpacing: 6, children: [
          for (final t in EventType.values)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, color: t.color, size: 10),
              const SizedBox(width: 5),
              Text(t == EventType.other ? 'Other' : t.label,
                  style: AppTheme.inter(size: 11, color: AppTheme.textSecondary)),
            ]),
        ]),
      ],
    );
  }

  Widget _eventCard(BuildContext context, EventMatch ewd) =>
      EventCard(event: ewd.event, distanceKm: ewd.distanceKm);
}
