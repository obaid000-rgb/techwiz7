import 'package:cloud_firestore/cloud_firestore.dart';

/// One agenda slot inside an event, stored embedded in the event document's
/// `sessions` list (no subcollection, so one read loads the whole agenda).
class EventSession {
  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String stage;
  final String description;

  const EventSession({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.stage = '',
    this.description = '',
  });

  /// Returns null for a malformed entry (no title or times), which the
  /// event skips instead of failing to load.
  static EventSession? tryFromMap(Object? raw) {
    if (raw is! Map) return null;
    final start = raw['startAt'];
    final end = raw['endAt'];
    final title = raw['title'];
    if (start is! Timestamp || end is! Timestamp || title is! String) return null;
    return EventSession(
      id: raw['id'] as String? ?? '${start.millisecondsSinceEpoch}',
      title: title,
      startAt: start.toDate(),
      endAt: end.toDate(),
      stage: raw['stage'] as String? ?? '',
      description: raw['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'stage': stage,
        'description': description,
      };

  EventSession copyWith({
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    String? stage,
    String? description,
  }) =>
      EventSession(
        id: id,
        title: title ?? this.title,
        startAt: startAt ?? this.startAt,
        endAt: endAt ?? this.endAt,
        stage: stage ?? this.stage,
        description: description ?? this.description,
      );
}
