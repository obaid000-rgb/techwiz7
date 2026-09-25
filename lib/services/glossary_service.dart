import '../models/glossary_term.dart';
import 'firestore_db.dart';

class GlossaryService {
  static final GlossaryService instance = GlossaryService._();
  GlossaryService._();

  Stream<List<GlossaryTerm>> watchTerms() => FirestoreDb.instance
      .collection('glossary')
      .orderBy('term')
      .snapshots()
      .map((s) => s.docs.map((d) => GlossaryTerm.fromMap(d.data(), d.id)).toList());

  Future<void> addTerm(GlossaryTerm term) =>
      FirestoreDb.instance.collection('glossary').add(term.toMap());

  Future<void> updateTerm(GlossaryTerm term) => FirestoreDb.instance
      .collection('glossary')
      .doc(term.id)
      .update(term.toMap());

  Future<void> deleteTerm(String id) =>
      FirestoreDb.instance.collection('glossary').doc(id).delete();
}
