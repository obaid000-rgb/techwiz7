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
  final String category;
  final double? latitude;
  final double? longitude;

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
  });

  bool get hasCoordinates => latitude != null && longitude != null;

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
      );

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
      );
}
