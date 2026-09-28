class AppCategory {
  final String id;
  final String key;
  final String name;
  final String? imageUrl;
  final String status; // 'active' | 'inactive'
  final int order;
  final String description; // optional short tagline/summary
  final bool isFeaturedInCarousel;
  final bool showInOnboarding;

  const AppCategory({
    required this.id,
    required this.key,
    required this.name,
    this.imageUrl,
    this.status = 'active',
    this.order = 0,
    this.description = '',
    this.isFeaturedInCarousel = false,
    this.showInOnboarding = false,
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
        showInOnboarding: map['showInOnboarding'] is bool
            ? map['showInOnboarding'] as bool
            : false,
      );

  Map<String, dynamic> toMap() => {
        'key': key,
        'name': name,
        'status': status,
        'order': order,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'description': description,
        'isFeaturedInCarousel': isFeaturedInCarousel,
        'showInOnboarding': showInOnboarding,
      };

  AppCategory copyWith({
    String? key,
    String? name,
    String? imageUrl,
    String? status,
    int? order,
    String? description,
    bool? isFeaturedInCarousel,
    bool? showInOnboarding,
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
        showInOnboarding: showInOnboarding ?? this.showInOnboarding,
      );
}
