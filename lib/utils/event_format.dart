/// Date and time labels for events (no intl dependency in this app).
library;

const List<String> _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _longMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "10:00 AM"
String formatEventTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "Oct 14", plus the year when it isn't [now]'s year: "Oct 14, 2027".
String formatEventDay(DateTime d, {DateTime? now}) {
  final label = '${_shortMonths[d.month - 1]} ${d.day}';
  return d.year == (now ?? DateTime.now()).year ? label : '$label, ${d.year}';
}

/// "October 14, 2026", the label events used before start times existed.
String formatEventLongDate(DateTime d) => '${_longMonths[d.month - 1]} ${d.day}, ${d.year}';

/// "Tue, Oct 14", used as the agenda's day headings.
String formatAgendaDay(DateTime d, {DateTime? now}) =>
    '${_weekdays[d.weekday - 1]}, ${formatEventDay(d, now: now)}';

/// "Oct 14, 10:00 AM"
String formatEventDateTime(DateTime d, {DateTime? now}) =>
    '${formatEventDay(d, now: now)}, ${formatEventTime(d)}';

/// The event's time range for Event Detail:
///  - no end time and a midnight start (every event saved before start
///    times existed): the old all-day label, "October 14, 2026";
///  - no end time: "Oct 14, 10:00 AM";
///  - same day: "Oct 14, 10:00 AM to 6:00 PM";
///  - several days: "Oct 14, 10:00 AM to Oct 16, 6:00 PM".
String formatEventRange(DateTime start, DateTime? end, {DateTime? now}) {
  if (end == null) {
    return start.hour == 0 && start.minute == 0
        ? formatEventLongDate(start)
        : formatEventDateTime(start, now: now);
  }
  final from = formatEventDateTime(start, now: now);
  return _sameDay(start, end)
      ? '$from to ${formatEventTime(end)}'
      : '$from to ${formatEventDateTime(end, now: now)}';
}
