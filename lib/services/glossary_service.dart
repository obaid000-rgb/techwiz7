import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/glossary_term.dart';

class GlossaryService {
  GlossaryService._();

  static final _collection = FirebaseFirestore.instance.collection('glossary');

  static Stream<List<GlossaryTerm>> streamTerms() {
    return _collection.orderBy('term').snapshots().map(
          (snapshot) => snapshot.docs.map(GlossaryTerm.fromDoc).toList(),
    );
  }
}
