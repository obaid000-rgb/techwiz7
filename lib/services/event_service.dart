import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_item.dart';
import 'firestore_db.dart';

class EventService {
  static final EventService instance = EventService._();
  EventService._();

  /// Every event, past and unpublished included — used by the admin screens.
  Stream<List<EventItem>> watchEvents() => FirestoreDb.instance
      .collection('events')
      .orderBy('date')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => EventItem.fromMap(d.data(), d.id)).toList());

  /// Fan-facing Event Discovery: published events that haven't ended.
  ///
  /// This used to be a Firestore range filter on `date >= start of today`,
  /// which hid a multi-day convention from its second day on. Past events
  /// are now dropped on the device by [EventItem.isVisibleToFans] (end time,
  /// or end of the start day when there is none), and unpublished ones the
  /// same way. The query itself has no `where` at all: a `where` on
  /// `isPublished` would also hide every event saved before that field
  /// existed, because Firestore skips documents missing the field. It keeps
  /// the single-field `orderBy('date')`, so the list stays date-ordered.
  /// Callers re-check [EventItem.isVisibleToFans] so a long-open app drops
  /// events once they end without waiting for a new snapshot.
  Stream<List<EventItem>> watchUpcomingEvents() => watchEvents()
      .map((events) => events.where((e) => e.isVisibleToFans()).toList());

  /// Home's "Trending Events": the admin-flagged events among the upcoming
  /// ones — built on [watchUpcomingEvents], so ended and unpublished events
  /// are excluded by the same rule, and date-ordered. The flag is filtered
  /// on the device.
  Stream<List<EventItem>> watchTrendingEvents() => watchUpcomingEvents()
      .map((events) => events.where((e) => e.isTrendingOnHome).toList());

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

  // Events linked to one fandom: a single array-contains query on
  // fandomIds, with no orderBy, so Firestore needs no composite index.
  // Ended and unpublished events are dropped with the same
  // isVisibleToFans check the Events tab uses, and the rest are sorted by
  // date on the device.
  Stream<List<EventItem>> watchEventsByFandom(String fandomId) =>
      FirestoreDb.instance
          .collection('events')
          .where('fandomIds', arrayContains: fandomId)
          .snapshots()
          .map((s) => s.docs
              .map((d) => EventItem.fromMap(d.data(), d.id))
              .where((e) => e.isVisibleToFans())
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date)));

  Future<void> addEvent(EventItem event) =>
      FirestoreDb.instance.collection('events').add(
          {...event.toMap(), 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> updateEvent(EventItem event) => FirestoreDb.instance
      .collection('events')
      .doc(event.id)
      .update({...event.toMap(), 'updatedAt': FieldValue.serverTimestamp()});

  /// Unpublish (hide from every fan screen) or republish an event. Events
  /// are never hard-deleted from the app, so an unpublish can be undone.
  Future<void> setPublished(String id, bool published) => FirestoreDb.instance
      .collection('events')
      .doc(id)
      .update({'isPublished': published, 'updatedAt': FieldValue.serverTimestamp()});

  /// One event, live (Event Detail's "X interested" and save state).
  Stream<EventItem?> watchEvent(String id) => FirestoreDb.instance
      .collection('events')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? EventItem.fromMap(d.data()!, d.id) : null);

  /// My Agenda sync: the event straight from the server (never the local
  /// cache), so an offline phone fails fast instead of reading stale data.
  /// Null when the event document no longer exists.
  Future<EventItem?> fetchFromServer(String id) async {
    final d = await FirestoreDb.instance
        .collection('events')
        .doc(id)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 8));
    return d.exists ? EventItem.fromMap(d.data()!, d.id) : null;
  }

  /// Save to / remove from My Agenda: one transaction changes the fan's
  /// savedEventIds and the event's interestedCount together, so the two
  /// can never disagree. It reads the fan's list first, so a repeat save
  /// or an unsave of something not saved is a no-op that never touches the
  /// count. The count moves by FieldValue.increment(±1), which the security
  /// rule checks against the stored value (and against the list change).
  /// Returns the event as read in the transaction (for the offline copy).
  Future<EventItem?> setSaved(String uid, String eventId, bool save) {
    final db = FirestoreDb.instance;
    final userRef = db.collection('users').doc(uid);
    final eventRef = db.collection('events').doc(eventId);
    return db.runTransaction((tx) async {
      final user = await tx.get(userRef);
      final eventDoc = await tx.get(eventRef);
      final raw = user.data()?['savedEventIds'];
      final ids = raw is List ? raw.whereType<String>().toList() : const <String>[];
      final data = eventDoc.data();
      final event = data == null ? null : EventItem.fromMap(data, eventDoc.id);
      if (save) {
        if (ids.contains(eventId)) return event;
        if (event == null || !event.isPublished) {
          throw const SaveEventException('This event is no longer listed.');
        }
        tx.update(userRef, {'savedEventIds': FieldValue.arrayUnion([eventId])});
        tx.update(eventRef, {'interestedCount': FieldValue.increment(1)});
        return event.copyWith(interestedCount: event.interestedCount + 1);
      }
      if (!ids.contains(eventId)) return event;
      tx.update(userRef, {'savedEventIds': FieldValue.arrayRemove([eventId])});
      // A deleted event has no count to lower; never go below 0.
      if (event != null && event.interestedCount > 0) {
        tx.update(eventRef, {'interestedCount': FieldValue.increment(-1)});
        return event.copyWith(interestedCount: event.interestedCount - 1);
      }
      return event;
    });
  }
}

class SaveEventException implements Exception {
  final String message;
  const SaveEventException(this.message);
  @override
  String toString() => message;
}
