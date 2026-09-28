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
  // Daily view tracking for the "Trending Today" badge. Written only by
  // PostService.recordView's transaction — deliberately left out of toMap()
  // so admin edits (update(toMap())) never reset or roll back the counts.
  final int todayViewCount;
  final String todayViewDate; // local date "yyyy-MM-dd", '' = never viewed
  final String fandomId;
  final String fandomName;
  final List<String> tags;
  final String creatorId;
  final String creatorName;
  final List<String> mediaUrls;
  final String audioUrl;
  final String sourceUrl;
  final int durationSeconds;
  // All-time views, written only by PostService.recordView's transaction —
  // left out of toMap() for the same reason as the Trending Today counters.
  final int viewCount;

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
    this.todayViewCount = 0,
    this.todayViewDate = '',
    this.fandomId = '',
    this.fandomName = '',
    this.tags = const [],
    this.creatorId = '',
    this.creatorName = '',
    this.mediaUrls = const [],
    this.audioUrl = '',
    this.sourceUrl = '',
    this.durationSeconds = 0,
    this.viewCount = 0,
  });

  bool get isActive => status == 'active';
  bool get hasCreator => creatorId.isNotEmpty;
  bool get hasFandom => fandomId.isNotEmpty;
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
    todayViewCount: (map['todayViewCount'] as num?)?.toInt() ?? 0,
    todayViewDate: map['todayViewDate'] as String? ?? '',
    fandomId: map['fandomId'] is String ? map['fandomId'] as String : '',
    fandomName: map['fandomName'] is String ? map['fandomName'] as String : '',
    tags: _stringList(map['tags']),
    creatorId: map['creatorId'] is String ? map['creatorId'] as String : '',
    creatorName: map['creatorName'] is String ? map['creatorName'] as String : '',
    mediaUrls: _stringList(map['mediaUrls']),
    audioUrl: map['audioUrl'] is String ? map['audioUrl'] as String : '',
    sourceUrl: map['sourceUrl'] is String ? map['sourceUrl'] as String : '',
    durationSeconds: map['durationSeconds'] is num
        ? (map['durationSeconds'] as num).toInt()
        : 0,
    viewCount: map['viewCount'] is num ? (map['viewCount'] as num).toInt() : 0,
  );

  static List<String> _stringList(Object? raw) =>
      raw is List ? raw.whereType<String>().toList() : const [];

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
    'fandomId': fandomId,
    'fandomName': fandomName,
    'tags': tags,
    'creatorId': creatorId,
    'creatorName': creatorName,
    'mediaUrls': mediaUrls,
    'audioUrl': audioUrl,
    'sourceUrl': sourceUrl,
    'durationSeconds': durationSeconds,
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
    String? fandomId,
    String? fandomName,
    List<String>? tags,
    String? creatorId,
    String? creatorName,
    List<String>? mediaUrls,
    String? audioUrl,
    String? sourceUrl,
    int? durationSeconds,
  }) => Post(
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
    todayViewCount: todayViewCount,
    todayViewDate: todayViewDate,
    fandomId: fandomId ?? this.fandomId,
    fandomName: fandomName ?? this.fandomName,
    tags: tags ?? this.tags,
    creatorId: creatorId ?? this.creatorId,
    creatorName: creatorName ?? this.creatorName,
    mediaUrls: mediaUrls ?? this.mediaUrls,
    audioUrl: audioUrl ?? this.audioUrl,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    viewCount: viewCount,
  );
}
