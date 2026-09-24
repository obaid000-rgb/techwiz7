import '../models/glossary_term.dart';

class GlossaryService {
  Future<List<GlossaryTerm>> fetchTerms() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }
}