class AppCategory {
  final String id;
  final String key;
  final String name;
  final String? imageUrl;
  final String status; // 'active' | 'inactive'
  final int order;
  final String description; // optional short tagline/summary
  final bool isFeaturedInCarousel;

  const AppCategory({
    required this.id,
    required this.key,
    required this.name,
    this.imageUrl,
    this.status = 'active',
    this.order = 0,
    this.description = '',
    this.isFeaturedInCarousel = false,
  });

  bool get isActive => status == 'active';

  factory AppCategory.fromMap(Map<String, dynamic> map, String docId) =>
      AppCategory(
        id: docId,
        key: map['key'] ?? docId,
        name: map['name'] ?? '',
        imageUrl: map['imageUrl'] as String?,
        status: (map['status'] as String?) ?? 'active',
        order: (map['order'] as num?)?.toInt() ?? 0,
        description: map['description'] ?? '',
        isFeaturedInCarousel: map['isFeaturedInCarousel'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'key': key,
        'name': name,
        'status': status,
        'order': order,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'description': description,
        'isFeaturedInCarousel': isFeaturedInCarousel,
      };

  AppCategory copyWith({
    String? key,
    String? name,
    String? imageUrl,
    String? status,
    int? order,
    String? description,
    bool? isFeaturedInCarousel,
  }) =>
      AppCategory(
        id: id,
        key: key ?? this.key,
        name: name ?? this.name,
        imageUrl: imageUrl ?? this.imageUrl,
        status: status ?? this.status,
        order: order ?? this.order,
        description: description ?? this.description,
        isFeaturedInCarousel: isFeaturedInCarousel ?? this.isFeaturedInCarousel,
      );
}
