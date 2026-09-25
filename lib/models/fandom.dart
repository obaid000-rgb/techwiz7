class Fandom {
  final int id;
  final String title;
  final String category;
  final String depth;
  final String badge;
  final String img;
  final String summary;
  final String fullBody;

  Fandom({
    required this.id,
    required this.title,
    required this.category,
    required this.depth,
    required this.badge,
    required this.img,
    required this.summary,
    required this.fullBody,
  });

  factory Fandom.fromMap(Map<String, dynamic> map, String docId) {
    return Fandom(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      depth: map['depth'] ?? 'Beginner',
      badge: map['badge'] ?? '',
      img: map['img'] ?? '',
      summary: map['summary'] ?? '',
      fullBody: map['fullBody'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'depth': depth,
        'badge': badge,
        'img': img,
        'summary': summary,
        'fullBody': fullBody,
      };
}
