import '../models/event_item.dart';
import 'firestore_db.dart';

class EventService {
  static final EventService instance = EventService._();
  EventService._();

  Stream<List<EventItem>> watchEvents() => FirestoreDb.instance
      .collection('events')
      .orderBy('date')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => EventItem.fromMap(d.data(), d.id)).toList());

  Future<void> addEvent(EventItem event) =>
      FirestoreDb.instance.collection('events').add(event.toMap());

  Future<void> updateEvent(EventItem event) => FirestoreDb.instance
      .collection('events')
      .doc(event.id)
      .update(event.toMap());

  Future<void> deleteEvent(String id) =>
      FirestoreDb.instance.collection('events').doc(id).delete();
}
