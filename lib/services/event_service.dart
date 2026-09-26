import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_item.dart';
import 'firestore_db.dart';

class EventService {
  static final EventService instance = EventService._();
  EventService._();

  /// Every event, past included — used by the admin screens.
  Stream<List<EventItem>> watchEvents() => FirestoreDb.instance
      .collection('events')
      .orderBy('date')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => EventItem.fromMap(d.data(), d.id)).toList());

  /// Fan-facing Event Discovery: only events dated today or later. Same
  /// query as [watchEvents] plus a range filter on `date` (single-field, so
  /// no composite index). Compared by calendar day, not timestamp, so an
  /// event later today still shows. Callers also re-check
  /// [EventItem.isUpcoming] so a long-open app drops events after midnight.
  Stream<List<EventItem>> watchUpcomingEvents() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return FirestoreDb.instance
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .orderBy('date')
        .snapshots()
        .map((s) => s.docs
            .map((d) => EventItem.fromMap(d.data(), d.id))
            .where((e) => e.isUpcoming)
            .toList());
  }

  /// Distinct city names present in [events] (case/space-insensitive,
  /// first spelling wins), alphabetical. Derived from real event data.
  static List<String> distinctCities(List<EventItem> events) {
    final byKey = <String, String>{};
    for (final e in events) {
      final name = e.city.trim();
      if (name.isEmpty) continue;
      byKey.putIfAbsent(name.toLowerCase(), () => name);
    }
    return byKey.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Future<void> addEvent(EventItem event) =>
      FirestoreDb.instance.collection('events').add(event.toMap());

  Future<void> updateEvent(EventItem event) => FirestoreDb.instance
      .collection('events')
      .doc(event.id)
      .update(event.toMap());

  Future<void> deleteEvent(String id) =>
      FirestoreDb.instance.collection('events').doc(id).delete();
}
