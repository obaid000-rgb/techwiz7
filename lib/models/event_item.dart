import 'package:cloud_firestore/cloud_firestore.dart';
import '../logic/event_status.dart';
import 'event_session.dart';
import 'event_type.dart';

class EventItem {
  final String id;
  final String title;
  final String city;
  /// Start of the event (date and time). Events saved before start times
  /// existed hold midnight of their day.
  final DateTime date;
  /// Venue name, shown as "Venue name" in the admin form.
  final String venue;
  final String ticketLink;
  /// Display-only price text such as "Free" or "PKR 1,500".
  final String ticketPrice;
  final String imageUrl;
  final String category;
  final double? latitude;
  final double? longitude;
  /// Admin flag: show this event in Home's "Trending Events" section.
  /// Several events can be flagged at once.
  final bool isTrendingOnHome;
  final List<String> fandomIds;
  /// [EventType.key]; "other" when missing.
  final String type;
  /// End of the event; null means it ends at the end of its start day.
  final DateTime? endAt;
  final String address;
  final String organizerName;
  /// Agenda, kept sorted by start time.
  final List<EventSession> sessions;
  /// False once admin unpublishes the event: it disappears from every fan
  /// screen but stays in the admin list. Missing (older events) = true.
  final bool isPublished;
  /// Set on every admin save (server time); null on events never re-saved.
  final DateTime? updatedAt;
  /// Fans who saved this event to My Agenda. Changed only by the save
  /// transaction (±1); left out of [toMap] so an admin save never resets it.
  final int interestedCount;

  const EventItem({
    required this.id,
    required this.title,
    required this.city,
    required this.date,
    required this.venue,
    this.ticketLink = '',
    this.ticketPrice = '',
    this.imageUrl = '',
    this.category = '',
    this.latitude,
    this.longitude,
    this.isTrendingOnHome = false,
    this.fandomIds = const [],
    this.type = 'other',
    this.endAt,
    this.address = '',
    this.organizerName = '',
    this.sessions = const [],
    this.isPublished = true,
    this.updatedAt,
    this.interestedCount = 0,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  EventType get eventType => EventType.fromKey(type);

  /// When the event actually ends: [endAt], or the end of its start day.
  DateTime get effectiveEnd => eventEnd(this);

  EventStatus statusAt(DateTime now) => eventStatus(this, now);

  /// Whether fan screens (Events tab, Home, fandom Events tab) list this
  /// event: published and not yet ended. Replaces the old "dated today or
  /// later" check, so a multi-day convention stays listed until its last
  /// day is over rather than vanishing the day after it starts.
  bool isVisibleToFans([DateTime? now]) =>
      isPublished && statusAt(now ?? DateTime.now()) != EventStatus.ended;

  factory EventItem.fromMap(Map<String, dynamic> map, String docId) =>
      EventItem(
        id: docId,
        title: map['title'] ?? '',
        city: map['city'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        venue: map['venue'] ?? '',
        ticketLink: map['ticketLink'] ?? '',
        ticketPrice: map['ticketPrice'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        category: map['category'] ?? '',
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        isTrendingOnHome: map['isTrendingOnHome'] as bool? ?? false,
        fandomIds: map['fandomIds'] is List
            ? (map['fandomIds'] as List).whereType<String>().toList()
            : const [],
        type: EventType.fromKey(map['type'] as String?).key,
        endAt: (map['endAt'] as Timestamp?)?.toDate(),
        address: map['address'] as String? ?? '',
        organizerName: map['organizerName'] as String? ?? '',
        sessions: map['sessions'] is List
            ? sortSessions([
                for (final raw in map['sessions'] as List)
                  ?EventSession.tryFromMap(raw),
              ])
            : const [],
        isPublished: map['isPublished'] as bool? ?? true,
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
        interestedCount: map['interestedCount'] is num
            ? (map['interestedCount'] as num).toInt()
            : 0,
      );

  /// Every field, as plain Hive-storable values (dates as milliseconds),
  /// for the offline copy of a saved event.
  Map<String, dynamic> toJson() {
    int? ms(DateTime? d) => d?.millisecondsSinceEpoch;
    return {
      'id': id,
      'title': title,
      'city': city,
      'date': ms(date),
      'venue': venue,
      'ticketLink': ticketLink,
      'ticketPrice': ticketPrice,
      'imageUrl': imageUrl,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'isTrendingOnHome': isTrendingOnHome,
      'fandomIds': fandomIds,
      'type': type,
      'endAt': ms(endAt),
      'address': address,
      'organizerName': organizerName,
      'sessions': [
        for (final s in sessions)
          {
            'id': s.id,
            'title': s.title,
            'startAt': ms(s.startAt),
            'endAt': ms(s.endAt),
            'stage': s.stage,
            'description': s.description,
          },
      ],
      'isPublished': isPublished,
      'updatedAt': ms(updatedAt),
      'interestedCount': interestedCount,
    };
  }

  factory EventItem.fromJson(Map<dynamic, dynamic> j) {
    DateTime? dt(Object? v) => v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
    return EventItem(
      id: j['id'] as String? ?? '',
      title: j['title'] as String? ?? '',
      city: j['city'] as String? ?? '',
      date: dt(j['date']) ?? DateTime.now(),
      venue: j['venue'] as String? ?? '',
      ticketLink: j['ticketLink'] as String? ?? '',
      ticketPrice: j['ticketPrice'] as String? ?? '',
      imageUrl: j['imageUrl'] as String? ?? '',
      category: j['category'] as String? ?? '',
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      isTrendingOnHome: j['isTrendingOnHome'] as bool? ?? false,
      fandomIds: (j['fandomIds'] as List?)?.whereType<String>().toList() ?? const [],
      type: EventType.fromKey(j['type'] as String?).key,
      endAt: dt(j['endAt']),
      address: j['address'] as String? ?? '',
      organizerName: j['organizerName'] as String? ?? '',
      sessions: sortSessions([
        for (final s in (j['sessions'] as List? ?? const []))
          if (s is Map && dt(s['startAt']) != null && dt(s['endAt']) != null)
            EventSession(
              id: s['id'] as String? ?? '',
              title: s['title'] as String? ?? '',
              startAt: dt(s['startAt'])!,
              endAt: dt(s['endAt'])!,
              stage: s['stage'] as String? ?? '',
              description: s['description'] as String? ?? '',
            ),
      ]),
      isPublished: j['isPublished'] as bool? ?? true,
      updatedAt: dt(j['updatedAt']),
      interestedCount: (j['interestedCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Every field the admin form edits. `updatedAt` is added by
  /// EventService as a server timestamp; `endAt` is written as null when
  /// cleared so an edit can remove an end time.
  Map<String, dynamic> toMap() => {
        'title': title,
        'city': city,
        'date': Timestamp.fromDate(date),
        'venue': venue,
        'ticketLink': ticketLink,
        'ticketPrice': ticketPrice,
        'imageUrl': imageUrl,
        'category': category,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'isTrendingOnHome': isTrendingOnHome,
        'fandomIds': fandomIds,
        'type': type,
        'endAt': endAt == null ? null : Timestamp.fromDate(endAt!),
        'address': address,
        'organizerName': organizerName,
        'sessions': [for (final s in sortSessions(sessions)) s.toMap()],
        'isPublished': isPublished,
      };

  EventItem copyWith({
    String? title,
    String? city,
    DateTime? date,
    String? venue,
    String? ticketLink,
    String? ticketPrice,
    String? imageUrl,
    String? category,
    double? latitude,
    double? longitude,
    bool? isTrendingOnHome,
    List<String>? fandomIds,
    String? type,
    DateTime? endAt,
    bool clearEndAt = false,
    String? address,
    String? organizerName,
    List<EventSession>? sessions,
    bool? isPublished,
    int? interestedCount,
  }) =>
      EventItem(
        id: id,
        title: title ?? this.title,
        city: city ?? this.city,
        date: date ?? this.date,
        venue: venue ?? this.venue,
        ticketLink: ticketLink ?? this.ticketLink,
        ticketPrice: ticketPrice ?? this.ticketPrice,
        imageUrl: imageUrl ?? this.imageUrl,
        category: category ?? this.category,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isTrendingOnHome: isTrendingOnHome ?? this.isTrendingOnHome,
        fandomIds: fandomIds ?? this.fandomIds,
        type: type ?? this.type,
        endAt: clearEndAt ? null : (endAt ?? this.endAt),
        address: address ?? this.address,
        organizerName: organizerName ?? this.organizerName,
        sessions: sessions ?? this.sessions,
        isPublished: isPublished ?? this.isPublished,
        updatedAt: updatedAt,
        interestedCount: interestedCount ?? this.interestedCount,
      );
}
