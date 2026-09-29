import 'dart:math' as math;
import '../models/event_item.dart';

/// Events tab discovery filters: pure functions, no widgets, no Firebase.

enum EventDateRange {
  all('Any date'),
  today('Today'),
  thisWeek('This week'),
  thisMonth('This month');

  final String label;
  const EventDateRange(this.label);
}

/// Radius choices offered in the filter sheet (km).
const List<int> kEventRadiusOptions = [10, 25, 50, 100];

/// A fan's location for distance filtering and sorting.
typedef GeoPoint = ({double lat, double lng});

class EventFilter {
  final String query;
  /// [EventType.key]s; empty = every type.
  final Set<String> types;
  /// City names (matched case-insensitively); empty = every city.
  final Set<String> cities;
  final EventDateRange dateRange;
  /// null = any distance.
  final int? radiusKm;
  final bool myFandomsOnly;

  const EventFilter({
    this.query = '',
    this.types = const {},
    this.cities = const {},
    this.dateRange = EventDateRange.all,
    this.radiusKm,
    this.myFandomsOnly = false,
  });

  static const none = EventFilter();

  EventFilter copyWith({
    String? query,
    Set<String>? types,
    Set<String>? cities,
    EventDateRange? dateRange,
    int? radiusKm,
    bool clearRadius = false,
    bool? myFandomsOnly,
  }) =>
      EventFilter(
        query: query ?? this.query,
        types: types ?? this.types,
        cities: cities ?? this.cities,
        dateRange: dateRange ?? this.dateRange,
        radiusKm: clearRadius ? null : (radiusKm ?? this.radiusKm),
        myFandomsOnly: myFandomsOnly ?? this.myFandomsOnly,
      );

  /// Number of filter groups in use (search counts as one).
  int get activeCount =>
      (query.trim().isNotEmpty ? 1 : 0) +
      (types.isNotEmpty ? 1 : 0) +
      (cities.isNotEmpty ? 1 : 0) +
      (dateRange != EventDateRange.all ? 1 : 0) +
      (radiusKm != null ? 1 : 0) +
      (myFandomsOnly ? 1 : 0);

  /// Filters set inside the Filter sheet (everything except search and the
  /// type chips, which sit on the toolbar) — the Filter button's badge.
  int get sheetCount =>
      (cities.isNotEmpty ? 1 : 0) +
      (dateRange != EventDateRange.all ? 1 : 0) +
      (radiusKm != null ? 1 : 0) +
      (myFandomsOnly ? 1 : 0);

  bool get isEmpty => activeCount == 0;
}

/// An event that passed the filter, with its distance from the fan when
/// both the fan's location and the event's coordinates are known.
class EventMatch {
  final EventItem event;
  final double? distanceKm;
  const EventMatch(this.event, this.distanceKm);
}

/// Great-circle distance in km (haversine, mean Earth radius 6371 km).
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(a)));
}

/// [start, end) of [range] in device local time, or null for "any date".
/// This week runs Monday 00:00 to the next Monday 00:00.
(DateTime, DateTime)? dateRangeBounds(EventDateRange range, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (range) {
    case EventDateRange.all:
      return null;
    case EventDateRange.today:
      return (today, DateTime(today.year, today.month, today.day + 1));
    case EventDateRange.thisWeek:
      final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
      return (monday, DateTime(monday.year, monday.month, monday.day + 7));
    case EventDateRange.thisMonth:
      return (DateTime(today.year, today.month), DateTime(today.year, today.month + 1));
  }
}

/// Date-range overlap: the event runs over [start, end) (end = its end
/// time, or the end of its start day) and the range is [from, to). The two
/// overlap when the event starts before the range ends AND ends after the
/// range starts. So a convention from last Saturday to Tuesday matches
/// "This week" and "Today" on each of its days, not only on its first day.
bool overlapsRange(EventItem e, DateTime from, DateTime to) =>
    e.date.isBefore(to) && e.effectiveEnd.isAfter(from);

final RegExp _wordSplit = RegExp(r'[^a-z0-9]+');

List<String> _words(String s) =>
    s.toLowerCase().split(_wordSplit).where((w) => w.isNotEmpty).toList();

/// Case-insensitive prefix search: every word typed must be the start of a
/// word in the title, venue name, city or organizer ("kar" -> Karachi).
bool matchesQuery(EventItem e, String query) {
  final typed = _words(query);
  if (typed.isEmpty) return true;
  final words = [
    ..._words(e.title),
    ..._words(e.venue),
    ..._words(e.city),
    ..._words(e.organizerName),
  ];
  return typed.every((q) => words.any((w) => w.startsWith(q)));
}

/// Applies [filter] to [events]:
///  - ended and unpublished events are always excluded (E1's status);
///  - groups combine with AND, choices inside a group with OR;
///  - radius needs [userLocation] and is ignored without it (events with
///    no coordinates don't pass an active radius);
///  - "My fandoms" keeps events linked to any of [followedFandomIds].
/// Sorted nearest first when [userLocation] is known (events without
/// coordinates after, by start time), otherwise by start time.
List<EventMatch> applyEventFilter(
  List<EventItem> events,
  EventFilter filter,
  GeoPoint? userLocation,
  List<String> followedFandomIds,
  DateTime now,
) {
  final bounds = dateRangeBounds(filter.dateRange, now);
  final cities = {for (final c in filter.cities) normalizeCity(c)};
  final followed = followedFandomIds.toSet();
  final out = <EventMatch>[];
  for (final e in events) {
    if (!e.isVisibleToFans(now)) continue;
    if (filter.types.isNotEmpty && !filter.types.contains(e.type)) continue;
    if (cities.isNotEmpty && !cities.contains(normalizeCity(e.city))) continue;
    if (bounds != null && !overlapsRange(e, bounds.$1, bounds.$2)) continue;
    if (!matchesQuery(e, filter.query)) continue;
    if (filter.myFandomsOnly && !e.fandomIds.any(followed.contains)) continue;
    final distance = userLocation != null && e.hasCoordinates
        ? haversineKm(userLocation.lat, userLocation.lng, e.latitude!, e.longitude!)
        : null;
    if (filter.radiusKm != null && userLocation != null) {
      if (distance == null || distance > filter.radiusKm!) continue;
    }
    out.add(EventMatch(e, distance));
  }
  out.sort((a, b) {
    final da = a.distanceKm, db = b.distanceKm;
    if (da != null && db != null) return da.compareTo(db);
    if (da != null) return -1;
    if (db != null) return 1;
    return a.event.date.compareTo(b.event.date);
  });
  return out;
}

/// Distinct city names among events fans can still see (not ended, not
/// unpublished), matched with [normalizeCity] ("Karachi Division" and
/// "karachi " are one city) and shown with [displayCity], sorted.
List<String> availableCities(List<EventItem> events, [DateTime? now]) {
  final at = now ?? DateTime.now();
  final byKey = <String, String>{};
  for (final e in events) {
    final name = displayCity(e.city);
    if (name.isEmpty || !e.isVisibleToFans(at)) continue;
    byKey.putIfAbsent(normalizeCity(name), () => name);
  }
  return byKey.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}

// ── City names ────────────────────────────────────────────────────────────
// The admin form fills City from the map pin (OpenStreetMap), which returns
// region names like "Karachi Division", while a fan's detected city is
// "Karachi" and typed ones vary ("karachi ", "Karachi City"). Cities are
// always compared through normalizeCity.

final RegExp _citySuffix =
    RegExp(r'\s+(division|district|city|metropolitan( city)?|municipality|tehsil)$', caseSensitive: false);

/// [city] without surrounding spaces, doubled spaces or an administrative
/// suffix ("Karachi Division" → "Karachi"), keeping its capitalisation.
String displayCity(String city) {
  final clean = city.trim().replaceAll(RegExp(r'\s+'), ' ');
  final stripped = clean.replaceFirst(_citySuffix, '');
  return stripped.isEmpty ? clean : stripped;
}

/// Comparison key for a city: [displayCity], lower-cased.
String normalizeCity(String city) => displayCity(city).toLowerCase();

// ── "Near you" ─────────────────────────────────────────────────────────────

/// "Near you" radius (km).
const double kNearYouKm = 50;

/// The "Near you" row: events within [kNearYouKm] of the fan, or in the
/// fan's detected city (so events saved without map coordinates still
/// count), nearest first (events without a distance last, by date).
/// Only used for this row; it never filters the main list.
List<EventMatch> nearYouEvents(List<EventMatch> all, String? detectedCity) {
  final city = detectedCity == null ? null : normalizeCity(detectedCity);
  final out = [
    for (final m in all)
      if ((m.distanceKm != null && m.distanceKm! <= kNearYouKm) ||
          (city != null && city.isNotEmpty && normalizeCity(m.event.city) == city))
        m,
  ];
  out.sort((a, b) {
    final da = a.distanceKm, db = b.distanceKm;
    if (da != null && db != null) return da.compareTo(db);
    if (da != null) return -1;
    if (db != null) return 1;
    return a.event.date.compareTo(b.event.date);
  });
  return out;
}

/// [all] soonest first (for "All upcoming events").
List<EventMatch> soonestFirst(List<EventMatch> all) =>
    List.of(all)..sort((a, b) => a.event.date.compareTo(b.event.date));
