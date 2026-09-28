import 'package:flutter_test/flutter_test.dart';
import 'package:fandom_verse/logic/event_status.dart';
import 'package:fandom_verse/models/event_item.dart';
import 'package:fandom_verse/models/event_session.dart';
import 'package:fandom_verse/utils/event_format.dart';

EventItem _event({
  required DateTime start,
  DateTime? end,
  List<EventSession> sessions = const [],
  String ticketLink = '',
  bool pinned = true,
  bool published = true,
}) =>
    EventItem(
      id: 'e',
      title: 'Expo',
      city: 'Lahore',
      date: start,
      venue: 'Expo Centre',
      endAt: end,
      sessions: sessions,
      ticketLink: ticketLink,
      latitude: pinned ? 31.5 : null,
      longitude: pinned ? 74.3 : null,
      isPublished: published,
    );

EventSession _session(String id, DateTime start, DateTime end) =>
    EventSession(id: id, title: 'Panel $id', startAt: start, endAt: end);

void main() {
  group('eventStatus', () {
    // Three-day convention: Oct 14 10:00 to Oct 16 18:00.
    final start = DateTime(2026, 10, 14, 10);
    final end = DateTime(2026, 10, 16, 18);
    final multiDay = _event(start: start, end: end);

    test('multi-day event: upcoming, happening now on every day, then ended', () {
      expect(eventStatus(multiDay, DateTime(2026, 10, 14, 9, 59)), EventStatus.upcoming);
      expect(eventStatus(multiDay, start), EventStatus.happeningNow);
      expect(eventStatus(multiDay, DateTime(2026, 10, 15, 3)), EventStatus.happeningNow);
      expect(eventStatus(multiDay, DateTime(2026, 10, 16, 17, 59)), EventStatus.happeningNow);
      expect(eventStatus(multiDay, end), EventStatus.ended);
      expect(eventStatus(multiDay, DateTime(2026, 10, 17)), EventStatus.ended);
    });

    test('started yesterday, ends tomorrow: still listed for fans', () {
      final now = DateTime(2026, 9, 28, 12);
      final e = _event(
          start: DateTime(2026, 9, 27, 10), end: DateTime(2026, 9, 29, 18));
      expect(e.statusAt(now), EventStatus.happeningNow);
      expect(e.isVisibleToFans(now), isTrue);
    });

    test('no endAt: ends at the end of its start day', () {
      // An older event saved as a bare date (midnight).
      final legacy = _event(start: DateTime(2026, 10, 14));
      expect(eventEnd(legacy), DateTime(2026, 10, 15));
      expect(eventStatus(legacy, DateTime(2026, 10, 13, 23)), EventStatus.upcoming);
      expect(eventStatus(legacy, DateTime(2026, 10, 14, 0)), EventStatus.happeningNow);
      expect(eventStatus(legacy, DateTime(2026, 10, 14, 23, 59)), EventStatus.happeningNow);
      expect(eventStatus(legacy, DateTime(2026, 10, 15)), EventStatus.ended);
      expect(legacy.isVisibleToFans(DateTime(2026, 10, 14, 22)), isTrue);
      expect(legacy.isVisibleToFans(DateTime(2026, 10, 15, 0, 1)), isFalse);

      // With a start time: upcoming before it, on until midnight.
      final evening = _event(start: DateTime(2026, 10, 14, 19));
      expect(eventStatus(evening, DateTime(2026, 10, 14, 12)), EventStatus.upcoming);
      expect(eventStatus(evening, DateTime(2026, 10, 14, 21)), EventStatus.happeningNow);
    });

    test('unpublished events are never visible to fans', () {
      final e = _event(start: DateTime(2026, 10, 14), published: false);
      expect(e.isVisibleToFans(DateTime(2026, 10, 1)), isFalse);
    });
  });

  group('validateEvent', () {
    final start = DateTime(2026, 10, 14, 10);
    final end = DateTime(2026, 10, 16, 18);

    test('a valid multi-day event with sessions passes', () {
      final v = validateEvent(_event(start: start, end: end, ticketLink: 'https://t.pk', sessions: [
        _session('a', DateTime(2026, 10, 14, 10), DateTime(2026, 10, 14, 11)),
        _session('b', DateTime(2026, 10, 16, 17), DateTime(2026, 10, 16, 18)),
      ]));
      expect(v.isValid, isTrue);
    });

    test('end must be after start', () {
      expect(validateEvent(_event(start: start, end: start)).end, isNotNull);
      expect(validateEvent(_event(start: start, end: DateTime(2026, 10, 13))).end,
          'End time must be after the start time.');
    });

    test('session outside the event range is rejected', () {
      final v = validateEvent(_event(start: start, end: end, sessions: [
        _session('early', DateTime(2026, 10, 14, 9), DateTime(2026, 10, 14, 10, 30)),
        _session('late', DateTime(2026, 10, 16, 17), DateTime(2026, 10, 16, 19)),
        _session('ok', DateTime(2026, 10, 15, 12), DateTime(2026, 10, 15, 13)),
      ]));
      expect(v.isValid, isFalse);
      expect(v.sessions.keys, unorderedEquals(['early', 'late']));
      expect(v.sessions['early'], startsWith('Session must be within the event'));
    });

    test('with no endAt, sessions must fit inside the start day', () {
      final oneDay = _event(start: start, sessions: [
        _session('ok', DateTime(2026, 10, 14, 22), DateTime(2026, 10, 15)),
        _session('next', DateTime(2026, 10, 15, 9), DateTime(2026, 10, 15, 10)),
      ]);
      expect(validateEvent(oneDay).sessions.keys, ['next']);
    });

    test('session end must be after its own start', () {
      final s = _session('x', DateTime(2026, 10, 15, 12), DateTime(2026, 10, 15, 11));
      expect(validateSession(s, start, end), 'Session end time must be after its start time.');
    });

    test('ticket link must be empty or https', () {
      expect(validateEvent(_event(start: start)).ticketLink, isNull);
      expect(validateEvent(_event(start: start, ticketLink: 'HTTPS://t.pk')).ticketLink, isNull);
      expect(validateEvent(_event(start: start, ticketLink: 'http://t.pk')).ticketLink, isNotNull);
      expect(validateEvent(_event(start: start, ticketLink: 'tickets.pk')).ticketLink, isNotNull);
    });

    test('location must be set', () {
      expect(validateEvent(_event(start: start, pinned: false)).location, isNotNull);
      expect(validateEvent(_event(start: start)).location, isNull);
    });
  });

  test('sortSessions orders by start time', () {
    final sorted = sortSessions([
      _session('c', DateTime(2026, 10, 15, 9), DateTime(2026, 10, 15, 10)),
      _session('a', DateTime(2026, 10, 14, 9), DateTime(2026, 10, 14, 10)),
      _session('b', DateTime(2026, 10, 14, 14), DateTime(2026, 10, 14, 15)),
    ]);
    expect(sorted.map((s) => s.id), ['a', 'b', 'c']);
  });

  test('formatEventRange', () {
    final now = DateTime(2026, 9, 28);
    expect(formatEventRange(DateTime(2026, 10, 14, 10), DateTime(2026, 10, 16, 18), now: now),
        'Oct 14, 10:00 AM to Oct 16, 6:00 PM');
    expect(formatEventRange(DateTime(2026, 10, 14, 10), DateTime(2026, 10, 14, 18), now: now),
        'Oct 14, 10:00 AM to 6:00 PM');
    expect(formatEventRange(DateTime(2026, 10, 14), null, now: now), 'October 14, 2026');
    expect(formatEventRange(DateTime(2026, 10, 14, 12, 5), null, now: now), 'Oct 14, 12:05 PM');
  });

  test('older event documents load with safe defaults', () {
    final e = EventItem.fromMap({'title': 'Old', 'city': 'X', 'venue': 'V'}, 'id1');
    expect(e.type, 'other');
    expect(e.endAt, isNull);
    expect(e.sessions, isEmpty);
    expect(e.isPublished, isTrue);
    expect(e.address, '');
    expect(e.organizerName, '');
  });
}
