import 'package:cloud_firestore/cloud_firestore.dart';
import 'fandom.dart';

const List<String> kCreatorKinds = [
  'studio',
  'youtuber',
  'podcaster',
  'journalist',
  'community',
];

const Map<String, String> kCreatorKindLabels = {
  'studio': 'Studio',
  'youtuber': 'YouTuber',
  'podcaster': 'Podcaster',
  'journalist': 'Journalist',
  'community': 'Community',
};

class Creator {
  final String id;
  final String name;
  final String avatarUrl;
  final String kind;
  final String bio;
  final List<String> fandomIds;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  const Creator({
    required this.id,
    required this.name,
    this.avatarUrl = '',
    this.kind = 'community',
    this.bio = '',
    this.fandomIds = const [],
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
  });

  static String slugFor(String name) => Fandom.slugFor(name);

  factory Creator.fromMap(Map<String, dynamic> map, String docId) {
    String str(String key) => map[key] is String ? map[key] as String : '';
    final kind = str('kind');
    final ids = map['fandomIds'];
    final created = map['createdAt'];
    return Creator(
      id: docId,
      name: str('name'),
      avatarUrl: str('avatarUrl'),
      kind: kCreatorKinds.contains(kind) ? kind : 'community',
      bio: str('bio'),
      fandomIds: ids is List ? ids.whereType<String>().toList() : const [],
      isVerified: map['isVerified'] is bool ? map['isVerified'] as bool : false,
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'avatarUrl': avatarUrl,
        'kind': kind,
        'bio': bio,
        'fandomIds': fandomIds,
        'isVerified': isVerified,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Creator copyWith({
    String? name,
    String? avatarUrl,
    String? kind,
    String? bio,
    List<String>? fandomIds,
    bool? isVerified,
    bool? isActive,
  }) =>
      Creator(
        id: id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        kind: kind ?? this.kind,
        bio: bio ?? this.bio,
        fandomIds: fandomIds ?? this.fandomIds,
        isVerified: isVerified ?? this.isVerified,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
