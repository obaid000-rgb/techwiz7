import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarLibraryItem {
  static const general = 'general';

  final String id;
  final String imageUrl;
  final String categoryId;
  final bool isActive;
  final DateTime createdAt;

  const AvatarLibraryItem({
    required this.id,
    required this.imageUrl,
    this.categoryId = general,
    this.isActive = true,
    required this.createdAt,
  });

  factory AvatarLibraryItem.fromMap(Map<String, dynamic> map, String id) => AvatarLibraryItem(
        id: id,
        imageUrl: map['imageUrl'] as String? ?? '',
        categoryId: (map['categoryId'] as String?)?.isNotEmpty == true
            ? map['categoryId'] as String
            : general,
        isActive: map['isActive'] as bool? ?? true,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'imageUrl': imageUrl,
        'categoryId': categoryId,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
