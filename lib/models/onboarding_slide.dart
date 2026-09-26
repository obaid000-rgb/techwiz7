class OnboardingSlide {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int order;

  const OnboardingSlide({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl = '',
    this.order = 0,
  });

  factory OnboardingSlide.fromMap(Map<String, dynamic> map, String docId) =>
      OnboardingSlide(
        id: docId,
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        order: (map['order'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'order': order,
      };

  OnboardingSlide copyWith({
    String? title,
    String? description,
    String? imageUrl,
    int? order,
  }) =>
      OnboardingSlide(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        order: order ?? this.order,
      );
}
