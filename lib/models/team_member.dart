import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  final String id;
  final String name;
  final String role;
  final String bio;
  final String imageUrl;
  final int order;
  final DateTime createdAt;

  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.bio = '',
    this.imageUrl = '',
    this.order = 0,
    required this.createdAt,
  });

  factory TeamMember.fromMap(Map<String, dynamic> m, String id) => TeamMember(
        id: id,
        name: m['name'] as String? ?? '',
        role: m['role'] as String? ?? '',
        bio: m['bio'] as String? ?? '',
        imageUrl: m['imageUrl'] as String? ?? '',
        order: (m['order'] as num?)?.toInt() ?? 0,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
        'bio': bio,
        'imageUrl': imageUrl,
        'order': order,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
