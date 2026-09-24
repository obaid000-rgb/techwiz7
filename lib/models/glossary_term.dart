import 'package:cloud_firestore/cloud_firestore.dart';

class GlossaryTerm {
  final String id;
  final String term;
  final String definition;

  const GlossaryTerm({
    required this.id,
    required this.term,
    required this.definition,
  });

  factory GlossaryTerm.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return GlossaryTerm(
      id: doc.id,
      term: (data['term'] as String?)?.trim() ?? 'Untitled Term',
      definition: (data['definition'] as String?)?.trim() ?? '',
    );
  }
}