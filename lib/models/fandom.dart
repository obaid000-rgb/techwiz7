import 'package:cloud_firestore/cloud_firestore.dart';

class Fandom {
  final String id;
  final String categoryId;
  final String categoryName;
  final String name;
  final String description;
  final String coverImageUrl;
  final String logoUrl;
  final List<String> tags;
  final int followerCount;
  final bool isTrending;
  final bool isActive;
  final DateTime createdAt;
  final int viewCount;
  final int weekViewCount;
  final int weekFollowCount;
  final String weekKey;

  const Fandom({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    this.description = '',
    this.coverImageUrl = '',
    this.logoUrl = '',
    this.tags = const [],
    this.followerCount = 0,
    this.isTrending = false,
    this.isActive = true,
    required this.createdAt,
    this.viewCount = 0,
    this.weekViewCount = 0,
    this.weekFollowCount = 0,
    this.weekKey = '',
  });

  // Slug ID: lowercase, every run of non-alphanumeric characters becomes a
  // single hyphen, no leading/trailing hyphens ("Free Fire" → "free-fire",
  // "Spider-Man" → "spider-man"). Same approach as the category key, but
  // hyphenated. Assigned once at creation and never changed afterwards,
  // even if the fandom is renamed.
  static String slugFor(String name) => name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  factory Fandom.fromMap(Map<String, dynamic> map, String docId) {
    String str(String key) => map[key] is String ? map[key] as String : '';
    final rawTags = map['tags'];
    final created = map['createdAt'];
    return Fandom(
      id: docId,
      categoryId: str('categoryId'),
      categoryName: str('categoryName'),
      name: str('name'),
      description: str('description'),
      coverImageUrl: str('coverImageUrl'),
      logoUrl: str('logoUrl'),
      tags: rawTags is List ? rawTags.whereType<String>().toList() : const [],
      followerCount: map['followerCount'] is num
          ? (map['followerCount'] as num).toInt()
          : 0,
      isTrending: map['isTrending'] is bool ? map['isTrending'] as bool : false,
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      viewCount: _int(map['viewCount']),
      weekViewCount: _int(map['weekViewCount']),
      weekFollowCount: _int(map['weekFollowCount']),
      weekKey: str('weekKey'),
    );
  }

  static int _int(Object? v) => v is num ? v.toInt() : 0;

  Map<String, dynamic> toMap() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'name': name,
        'description': description,
        'coverImageUrl': coverImageUrl,
        'logoUrl': logoUrl,
        'tags': tags,
        'followerCount': followerCount,
        'isTrending': isTrending,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'viewCount': viewCount,
        'weekViewCount': weekViewCount,
        'weekFollowCount': weekFollowCount,
        'weekKey': weekKey,
      };

  Fandom copyWith({
    String? categoryId,
    String? categoryName,
    String? name,
    String? description,
    String? coverImageUrl,
    String? logoUrl,
    List<String>? tags,
    int? followerCount,
    bool? isTrending,
    bool? isActive,
  }) =>
      Fandom(
        id: id,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        name: name ?? this.name,
        description: description ?? this.description,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        logoUrl: logoUrl ?? this.logoUrl,
        tags: tags ?? this.tags,
        followerCount: followerCount ?? this.followerCount,
        isTrending: isTrending ?? this.isTrending,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        viewCount: viewCount,
        weekViewCount: weekViewCount,
        weekFollowCount: weekFollowCount,
        weekKey: weekKey,
      );
}
