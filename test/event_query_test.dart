import 'package:flutter_test/flutter_test.dart';
import 'package:fandom_verse/logic/event_query.dart';
import 'package:fandom_verse/models/event_item.dart';

// Wednesday 30 Sep 2026, noon.
final now = DateTime(2026, 9, 30, 12);

EventItem ev(
  String id, {
  required DateTime start,
  DateTime? end,
  String type = 'other',
  String city = 'Lahore',
  String venue = 'Expo Centre',
  String organizer = '',
  double? lat,
  double? lng,
  List<String> fandoms = const [],
  bool published = true,
}) =>
    EventItem(
      id: id,
      title: 'Event $id',
      city: city,
      date: start,
      endAt: end,
      venue: venue,
      type: type,
      organizerName: organizer,
      latitude: lat,
      longitude: lng,
      fandomIds: fandoms,
      isPublished: published,
    );

List<String> ids(List<EventMatch> m) => m.map((x) => x.event.id).toList();

// Lahore Gulberg as the fan's location.
const GeoPoint lahore = (lat: 31.52, lng: 74.35);

void main() {
  final screening = ev('screen', start: DateTime(2026, 10, 2, 19), type: 'screening', city: 'Karachi', lat: 24.86, lng: 67.0);
  final tourney = ev('tour', start: DateTime(2026, 10, 20, 10), type: 'tournament', lat: 31.47, lng: 74.27, fandoms: ['ff']);
  // Convention from last Saturday (26 Sep) to Tuesday (29 Sep)... ended yesterday.
  final ended = ev('ended', start: DateTime(2026, 9, 26, 10), end: DateTime(2026, 9, 29, 18), type: 'convention');
  // Multi-day convention running Saturday 26 Sep to Tuesday 6 Oct.
  final longCon = ev('con', start: DateTime(2026, 9, 26, 10), end: DateTime(2026, 10, 6, 18), type: 'convention',
      organizer: 'Comic Con PK', lat: 31.55, lng: 74.34, fandoms: ['naruto']);
  final unpublished = ev('hidden', start: DateTime(2026, 10, 3), published: false);
  final all = [screening, tourney, ended, longCon, unpublished];

  test('no filter: ended and unpublished excluded, sorted by start without location', () {
    expect(ids(applyEventFilter(all, EventFilter.none, null, const [], now)), ['con', 'screen', 'tour']);
  });

  test('type filter alone (OR within the group)', () {
    expect(ids(applyEventFilter(all, const EventFilter(types: {'screening'}), null, const [], now)), ['screen']);
    expect(ids(applyEventFilter(all, const EventFilter(types: {'screening', 'tournament'}), null, const [], now)),
        ['screen', 'tour']);
  });

  test('city filter alone, case-insensitive', () {
    expect(ids(applyEventFilter(all, const EventFilter(cities: {'karachi'}), null, const [], now)), ['screen']);
    expect(ids(applyEventFilter(all, const EventFilter(cities: {'Karachi', 'LAHORE'}), null, const [], now)),
        ['con', 'screen', 'tour']);
  });

  test('search: prefix match on title, venue, city and organizer', () {
    List<String> q(String s) => ids(applyEventFilter(all, EventFilter(query: s), null, const [], now));
    expect(q('kar'), ['screen']);
    expect(q('KAR'), ['screen']);
    expect(q('comic'), ['con']); // organizer
    expect(q('expo cen'), ['con', 'screen', 'tour']); // venue, every word
    expect(q('arachi'), isEmpty); // prefix only
    expect(q('   '), ['con', 'screen', 'tour']);
  });

  test('my fandoms alone', () {
    expect(ids(applyEventFilter(all, const EventFilter(myFandomsOnly: true), null, const ['naruto'], now)), ['con']);
    expect(ids(applyEventFilter(all, const EventFilter(myFandomsOnly: true), null, const [], now)), isEmpty);
  });

  test('date ranges: today, this week (Mon-Sun), this month', () {
    List<String> d(EventDateRange r) => ids(applyEventFilter(all, EventFilter(dateRange: r), null, const [], now));
    // The multi-day convention matches "today" though it started days ago.
    expect(d(EventDateRange.today), ['con']);
    // Week of Mon 28 Sep - Sun 4 Oct.
    expect(d(EventDateRange.thisWeek), ['con', 'screen']);
    expect(d(EventDateRange.thisMonth), ['con']);
  });

  test('this week includes a convention from last Saturday to Tuesday', () {
    // Now = Monday 28 Sep 09:00; the convention runs Sat 26 to Tue 29.
    final monday = DateTime(2026, 9, 28, 9);
    final satToTue = ev('sat', start: DateTime(2026, 9, 26, 10), end: DateTime(2026, 9, 29, 18));
    expect(ids(applyEventFilter([satToTue], const EventFilter(dateRange: EventDateRange.thisWeek), null, const [], monday)),
        ['sat']);
  });

  test('date ranges across a month boundary', () {
    // Now = Wed 30 Sep: "this week" runs to Sun 4 Oct; "this month" ends 1 Oct.
    final octThird = ev('oct3', start: DateTime(2026, 10, 3, 10));
    final octFifth = ev('oct5', start: DateTime(2026, 10, 5, 10));
    final spansIntoOct = ev('span', start: DateTime(2026, 9, 30, 20), end: DateTime(2026, 10, 2, 12));
    final list = [octThird, octFifth, spansIntoOct];
    expect(ids(applyEventFilter(list, const EventFilter(dateRange: EventDateRange.thisWeek), null, const [], now)),
        ['span', 'oct3']);
    expect(ids(applyEventFilter(list, const EventFilter(dateRange: EventDateRange.thisMonth), null, const [], now)),
        ['span']);
    // In October, the spanning event still matches "this month" on Oct 1.
    expect(ids(applyEventFilter(list, const EventFilter(dateRange: EventDateRange.thisMonth), null, const [],
        DateTime(2026, 10, 1, 8))), ['span', 'oct3', 'oct5']);
    expect(dateRangeBounds(EventDateRange.thisMonth, DateTime(2026, 12, 15)),
        (DateTime(2026, 12), DateTime(2027, 1)));
  });

  test('radius with location: nearby only, sorted by distance', () {
    final r = applyEventFilter(all, const EventFilter(radiusKm: 10), lahore, const [], now);
    expect(ids(r), ['con', 'tour']);
    expect(r.first.distanceKm, lessThan(r.last.distanceKm!));
    expect(r.every((m) => m.distanceKm! <= 10), isTrue);
    // No radius, with location: everything, nearest first; Karachi far away.
    final allNear = applyEventFilter(all, EventFilter.none, lahore, const [], now);
    expect(ids(allNear), ['con', 'tour', 'screen']);
    expect(allNear.last.distanceKm, greaterThan(900));
  });

  test('radius without location is ignored', () {
    expect(ids(applyEventFilter(all, const EventFilter(radiusKm: 10), null, const [], now)), ['con', 'screen', 'tour']);
  });

  test('combined filters AND across groups', () {
    const f = EventFilter(types: {'convention', 'screening'}, dateRange: EventDateRange.thisWeek, query: 'kar');
    expect(ids(applyEventFilter(all, f, null, const [], now)), ['screen']);
    const g = EventFilter(types: {'tournament'}, radiusKm: 25, myFandomsOnly: true);
    expect(ids(applyEventFilter(all, g, lahore, const ['ff'], now)), ['tour']);
    expect(ids(applyEventFilter(all, g, lahore, const ['naruto'], now)), isEmpty);
  });

  test('activeCount, sheetCount and copyWith', () {
    const f = EventFilter(query: 'x', types: {'screening'}, radiusKm: 10, myFandomsOnly: true);
    expect(f.activeCount, 4);
    expect(f.sheetCount, 2);
    expect(f.copyWith(clearRadius: true).radiusKm, isNull);
    expect(f.copyWith(query: '').activeCount, 3);
    expect(EventFilter.none.isEmpty, isTrue);
  });

  test('availableCities: visible events only, distinct, sorted', () {
    final extra = ev('x', start: DateTime(2026, 10, 9), city: 'lahore ');
    final gone = ev('g', start: DateTime(2026, 9, 1), city: 'Islamabad');
    expect(availableCities([...all, extra, gone], now), ['Karachi', 'Lahore']);
  });

  test('haversine: Lahore to Karachi is about 1030 km', () {
    expect(haversineKm(31.52, 74.35, 24.86, 67.0), closeTo(1030, 25));
  });

  group('cities and Near you', () {
    test('city names are normalized', () {
      expect(normalizeCity(' Karachi Division '), 'karachi');
      expect(normalizeCity('karachi'), 'karachi');
      expect(normalizeCity('Karachi City'), 'karachi');
      expect(displayCity('Karachi Division'), 'Karachi');
      expect(availableCities([
        ev('a', start: DateTime(2026, 10, 3), city: 'Karachi Division'),
        ev('b', start: DateTime(2026, 10, 4), city: 'karachi '),
        ev('c', start: DateTime(2026, 10, 5), city: 'Lahore'),
      ], now), ['Karachi', 'Lahore']);
    });

    test('city filter matches every spelling', () {
      final events = [
        ev('a', start: DateTime(2026, 10, 3), city: 'Karachi Division'),
        ev('b', start: DateTime(2026, 10, 4), city: 'Lahore'),
      ];
      expect(ids(applyEventFilter(events, const EventFilter(cities: {'Karachi'}), null, const [], now)), ['a']);
    });

    test('no filter: every city is listed, even with a location', () {
      final events = [
        ev('khi', start: DateTime(2026, 10, 3), city: 'Karachi', lat: 24.86, lng: 67.0),
        ev('lhr', start: DateTime(2026, 10, 4), city: 'Lahore', lat: 31.52, lng: 74.35),
        ev('isb', start: DateTime(2026, 10, 5), city: 'Islamabad'),
      ];
      const karachiFan = (lat: 24.87, lng: 67.02);
      final all = applyEventFilter(events, EventFilter.none, karachiFan, const [], now);
      expect(ids(soonestFirst(all)), ['khi', 'lhr', 'isb']);
      // Near you: within 50 km or in the fan's city; not Lahore/Islamabad.
      expect(ids(nearYouEvents(all, 'Karachi Division')), ['khi']);
      // An event without coordinates still counts when it's in the fan's city.
      final noCoords = applyEventFilter(
          [ev('k2', start: DateTime(2026, 10, 6), city: 'karachi')], EventFilter.none, karachiFan, const [], now);
      expect(ids(nearYouEvents(noCoords, 'Karachi')), ['k2']);
    });
  });
}
