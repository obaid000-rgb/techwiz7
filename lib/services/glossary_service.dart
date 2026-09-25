import '../models/glossary_term.dart';
import 'firestore_db.dart';

class GlossaryService {
  static final GlossaryService instance = GlossaryService._();
  GlossaryService._();

  Future<List<GlossaryTerm>> fetchTerms() async {
    final snapshot = await FirestoreDb.instance.collection('glossary').get();
    return snapshot.docs
        .map((d) => GlossaryTerm.fromMap(d.data()))
        .toList();
  }

  Future<List<GlossaryTerm>> fetchByCategory(String category) async {
    final snapshot = await FirestoreDb.instance
        .collection('glossary')
        .where('category', isEqualTo: category)
        .get();
    return snapshot.docs
        .map((d) => GlossaryTerm.fromMap(d.data()))
        .toList();
  }
}
