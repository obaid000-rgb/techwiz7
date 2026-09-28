class Merchandise {
  final String id;
  final String name;
  final double price;
  final String category;
  final String imageUrl;
  final String description;
  final String fandomId;
  final String fandomName;

  const Merchandise({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl = '',
    this.description = '',
    this.fandomId = '',
    this.fandomName = '',
  });

  bool get hasFandom => fandomId.isNotEmpty;

  factory Merchandise.fromMap(Map<String, dynamic> map, String docId) =>
      Merchandise(
        id: docId,
        name: map['name'] ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        category: map['category'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        description: map['description'] ?? '',
        fandomId: map['fandomId'] is String ? map['fandomId'] as String : '',
        fandomName:
            map['fandomName'] is String ? map['fandomName'] as String : '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'description': description,
        'fandomId': fandomId,
        'fandomName': fandomName,
      };

  Merchandise copyWith({
    String? name,
    double? price,
    String? category,
    String? imageUrl,
    String? description,
    String? fandomId,
    String? fandomName,
  }) =>
      Merchandise(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        description: description ?? this.description,
        fandomId: fandomId ?? this.fandomId,
        fandomName: fandomName ?? this.fandomName,
      );
}
