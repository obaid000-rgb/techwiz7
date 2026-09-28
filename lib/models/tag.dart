import 'package:cloud_firestore/cloud_firestore.dart';

class Tag {
  final String id; // the normalized slug, see normalizeTag()
  final String name;
  final bool isPinned;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.name,
    this.isPinned = false,
    required this.createdAt,
  });

  factory Tag.fromMap(Map<String, dynamic> map, String docId) {
    final created = map['createdAt'];
    final name = map['name'];
    return Tag(
      id: docId,
      name: name is String && name.trim().isNotEmpty ? name : docId,
      isPinned: map['isPinned'] is bool ? map['isPinned'] as bool : false,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'isPinned': isPinned,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
