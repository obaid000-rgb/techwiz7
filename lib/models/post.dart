import 'package:cloud_firestore/cloud_firestore.dart';

/// Matches the SRS Resources requirement's four content types exactly.
const List<String> kPostContentTypes = ['News', 'Gallery', 'Video', 'Podcast'];

/// '' = untagged (shows under "All" only, not under either depth filter).
const List<String> kPostContentDepths = ['beginner', 'deep'];

/// Deep Dive sub-type, only meaningful when contentDepth == 'deep'.
/// '' = untyped (shows under Deep Dive's "All" tab only).
const List<String> kDeepDiveTypes = ['trivia', 'lore', 'interview'];
const Map<String, String> kDeepDiveTypeLabels = {
  'trivia': 'Hidden Trivia',
  'lore': 'Advanced Lore',
  'interview': 'Interviews',
};

class Post {
  final String id;
  final String title;
  final String category;
  final String content;
  final String imageUrl;
  final DateTime createdAt;
  final String contentType; // News | Gallery | Video | Podcast
  final bool isFandomOfTheDay;
  final String status; // 'active' | 'inactive'
  final String? youtubeUrl;
  final String contentDepth; // '' | 'beginner' | 'deep'
  final String deepDiveType; // '' | 'trivia' | 'lore' | 'interview'

  const Post({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    this.imageUrl = '',
    required this.createdAt,
    this.contentType = 'News',
    this.isFandomOfTheDay = false,
    this.status = 'active',
    this.youtubeUrl,
    this.contentDepth = '',
    this.deepDiveType = '',
  });

  bool get isActive => status == 'active';
  bool get hasVideo => youtubeUrl != null && youtubeUrl!.isNotEmpty;

  factory Post.fromMap(Map<String, dynamic> map, String docId) => Post(
        id: docId,
        title: map['title'] ?? '',
        category: map['category'] ?? '',
        content: map['content'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        // Posts created before this field existed fall back to 'News'.
        contentType: kPostContentTypes.contains(map['contentType'])
            ? map['contentType'] as String
            : 'News',
        isFandomOfTheDay: map['isFandomOfTheDay'] as bool? ?? false,
        status: (map['status'] as String?) ?? 'active',
        youtubeUrl: map['youtubeUrl'] as String?,
        contentDepth: kPostContentDepths.contains(map['contentDepth'])
            ? map['contentDepth'] as String
            : '',
        deepDiveType: kDeepDiveTypes.contains(map['deepDiveType'])
            ? map['deepDiveType'] as String
            : '',
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'content': content,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'contentType': contentType,
        'isFandomOfTheDay': isFandomOfTheDay,
        'status': status,
        'contentDepth': contentDepth,
        'deepDiveType': deepDiveType,
        if (youtubeUrl != null) 'youtubeUrl': youtubeUrl,
      };

  Post copyWith({
    String? title,
    String? category,
    String? content,
    String? imageUrl,
    String? contentType,
    bool? isFandomOfTheDay,
    String? status,
    String? youtubeUrl,
    bool clearYoutubeUrl = false,
    String? contentDepth,
    String? deepDiveType,
  }) =>
      Post(
        id: id,
        title: title ?? this.title,
        category: category ?? this.category,
        content: content ?? this.content,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt,
        contentType: contentType ?? this.contentType,
        isFandomOfTheDay: isFandomOfTheDay ?? this.isFandomOfTheDay,
        status: status ?? this.status,
        youtubeUrl: clearYoutubeUrl ? null : (youtubeUrl ?? this.youtubeUrl),
        contentDepth: contentDepth ?? this.contentDepth,
        deepDiveType: deepDiveType ?? this.deepDiveType,
      );
}
