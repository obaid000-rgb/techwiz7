class GlossaryTerm {
  final String term;
  final String category;
  final String definition;

  GlossaryTerm({
    required this.term,
    required this.category,
    required this.definition,
  });

  factory GlossaryTerm.fromMap(Map<String, dynamic> map) {
    return GlossaryTerm(
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
}
