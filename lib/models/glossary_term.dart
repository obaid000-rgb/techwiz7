class GlossaryTerm {
  final String id;
  final String term;
  final String category;
  final String definition;

  const GlossaryTerm({
    required this.id,
    required this.term,
    this.category = '',
    required this.definition,
  });

  factory GlossaryTerm.fromMap(Map<String, dynamic> map, String docId) {
    return GlossaryTerm(
      id: docId,
      term: map['term'] ?? '',
      category: map['category'] ?? '',
      definition: map['definition'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'term': term,
        'category': category,
        'definition': definition,
      };

  GlossaryTerm copyWith({String? term, String? category, String? definition}) =>
      GlossaryTerm(
        id: id,
        term: term ?? this.term,
        category: category ?? this.category,
        definition: definition ?? this.definition,
      );
}
