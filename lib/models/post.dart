import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String title;
  final String category;
  final String content;
  final String imageUrl;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    this.imageUrl = '',
    required this.createdAt,
  });

  factory Post.fromMap(Map<String, dynamic> map, String docId) => Post(
        id: docId,
        title: map['title'] ?? '',
        category: map['category'] ?? '',
        content: map['content'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'content': content,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Post copyWith({
    String? title,
    String? category,
    String? content,
    String? imageUrl,
  }) =>
      Post(
        id: id,
        title: title ?? this.title,
        category: category ?? this.category,
        content: content ?? this.content,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt,
      );
}
