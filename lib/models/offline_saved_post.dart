import 'dart:typed_data';

class OfflineSavedPost {
  final String id;
  final String title;
  final String content;
  final String category;
  final String contentType;
  final DateTime savedAt;
  final Uint8List? imageBytes;

  const OfflineSavedPost({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.contentType,
    required this.savedAt,
    this.imageBytes,
  });

  factory OfflineSavedPost.fromMap(Map map) => OfflineSavedPost(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        content: map['content'] as String? ?? '',
        category: map['category'] as String? ?? '',
        contentType: map['contentType'] as String? ?? '',
        savedAt: DateTime.tryParse(map['savedAt'] as String? ?? '') ?? DateTime.now(),
        imageBytes: map['imageBytes'] as Uint8List?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'contentType': contentType,
        'savedAt': savedAt.toIso8601String(),
        'imageBytes': imageBytes,
      };
}
