import 'package:cloud_firestore/cloud_firestore.dart';

class EventItem {
  final String id;
  final String title;
  final String city;
  final DateTime date;
  final String venue;
  final String ticketLink;
  final String ticketPrice;
  final String imageUrl;

  const EventItem({
    required this.id,
    required this.title,
    required this.city,
    required this.date,
    required this.venue,
    this.ticketLink = '',
    this.ticketPrice = '',
    this.imageUrl = '',
  });

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
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'city': city,
        'date': Timestamp.fromDate(date),
        'venue': venue,
        'ticketLink': ticketLink,
        'ticketPrice': ticketPrice,
        'imageUrl': imageUrl,
      };

  EventItem copyWith({
    String? title,
    String? city,
    DateTime? date,
    String? venue,
    String? ticketLink,
    String? ticketPrice,
    String? imageUrl,
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
      );
}
