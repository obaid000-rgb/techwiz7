import '../models/event_item.dart';
import '../models/event_session.dart';
import '../utils/event_format.dart';

enum EventStatus { upcoming, happeningNow, ended }

/// When [event] ends. An event with no end time ends at the end of its
/// start day (midnight that night), so older events saved as a bare date
/// stay listed for the whole day they happen on.
DateTime eventEnd(EventItem event) => endFor(event.date, event.endAt);

/// [eventEnd] for a start and optional end that aren't in an EventItem yet
/// (the admin form validates before building one).
DateTime endFor(DateTime start, DateTime? endAt) =>
    endAt ?? DateTime(start.year, start.month, start.day + 1);

/// Event status at [now]:
///  - before the start time        -> upcoming
///  - from the start until the end -> happeningNow (a 3-day convention is
///    "happening now" on all three days)
///  - at or after the end          -> ended (fan screens hide it)
/// The end is [eventEnd]: the end time, or midnight after the start day.
EventStatus eventStatus(EventItem event, DateTime now) {
  if (now.isBefore(event.date)) return EventStatus.upcoming;
  if (now.isBefore(eventEnd(event))) return EventStatus.happeningNow;
  return EventStatus.ended;
}

/// Sessions in start-time order (ties by end time), as a new list.
List<EventSession> sortSessions(Iterable<EventSession> sessions) => sessions.toList()
  ..sort((a, b) {
    final byStart = a.startAt.compareTo(b.startAt);
    return byStart != 0 ? byStart : a.endAt.compareTo(b.endAt);
  });

/// Problems with one agenda session inside an event running from
/// [eventStart] to [eventEnd], or null when it's fine.
String? validateSession(EventSession session, DateTime eventStart, DateTime eventEnd) {
  if (session.title.trim().isEmpty) return 'Give the session a title.';
  if (!session.endAt.isAfter(session.startAt)) {
    return 'Session end time must be after its start time.';
  }
  if (session.startAt.isBefore(eventStart) || session.endAt.isAfter(eventEnd)) {
    return 'Session must be within the event: '
        '${formatEventDateTime(eventStart)} to ${formatEventDateTime(eventEnd)}.';
  }
  return null;
}

/// Result of [validateEvent]: one message per problem field, all null
/// (and no session entries) when the event can be saved.
class EventValidation {
  final String? end;
  final String? ticketLink;
  final String? location;
  /// Session id -> message.
  final Map<String, String> sessions;

  const EventValidation({this.end, this.ticketLink, this.location, this.sessions = const {}});

  bool get isValid => end == null && ticketLink == null && location == null && sessions.isEmpty;
}

/// Checks the rules the admin form enforces before saving:
///  - the end time (if set) is after the start;
///  - every session has its own end after its start and sits inside the
///    event's time range (up to the end of the start day with no end time);
///  - the ticket link is empty or starts with https://;
///  - the location is set (a map pin).
EventValidation validateEvent(EventItem event) {
  final end = event.endAt;
  final endError = end != null && !end.isAfter(event.date)
      ? 'End time must be after the start time.'
      : null;
  final link = event.ticketLink.trim();
  final linkError = link.isEmpty || link.toLowerCase().startsWith('https://')
      ? null
      : 'Ticket link must start with https:// (secure link).';
  final locationError =
      event.hasCoordinates ? null : 'Drop a pin on the map to set the event location.';
  final eventEndsAt = eventEnd(event);
  final sessionErrors = <String, String>{
    for (final s in event.sessions)
      s.id: ?validateSession(s, event.date, eventEndsAt),
  };
  return EventValidation(
    end: endError,
    ticketLink: linkError,
    location: locationError,
    sessions: sessionErrors,
  );
}

/// Fan-facing label for a status: COMING SOON before the start, NOW while
/// the event runs, CLOSED once it has ended.
String eventStatusLabel(EventStatus s) => switch (s) {
      EventStatus.upcoming => 'COMING SOON',
      EventStatus.happeningNow => 'NOW',
      EventStatus.ended => 'CLOSED',
    };

/// Admin form date/time rules, compared as DateTime values (never strings),
/// all in device local time:
///  - a start is required;
///  - a new event, or a changed start, can't begin in the past;
///  - a changed end can't be in the past;
///  - the end, when set, must be after the start (equal is not allowed).
/// An existing event that is already running can still be edited as long
/// as its start and end are left unchanged ([previousStart]/[previousEnd]).
String? validateEventTiming({
  required DateTime? start,
  required DateTime? end,
  required DateTime now,
  bool isNew = true,
  DateTime? previousStart,
  DateTime? previousEnd,
}) {
  if (start == null) return 'Choose a start date and time.';
  final startChanged = isNew || previousStart != start;
  final endChanged = isNew || previousEnd != end;
  if (startChanged && start.isBefore(now)) {
    return 'The start date and time cannot be in the past.';
  }
  if (end != null) {
    if (!end.isAfter(start)) return 'End time must be after the start time.';
    if (endChanged && end.isBefore(now)) return 'The end date and time cannot be in the past.';
  }
  return null;
}
