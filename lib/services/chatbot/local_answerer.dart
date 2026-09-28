import '../../models/faq.dart';
import '../../models/glossary_term.dart';

/// A reply built on the device, without Gemini.
class LocalAnswer {
  final String text;
  /// True when an FAQ or glossary entry matched; false for the "needs
  /// internet" reply.
  final bool matched;
  const LocalAnswer(this.text, {required this.matched});
}

const _stopWords = {
  'a', 'an', 'the', 'is', 'are', 'am', 'was', 'be', 'to', 'of', 'in', 'on', 'at', 'for', 'and',
  'or', 'i', 'me', 'my', 'you', 'your', 'it', 'its', 'do', 'does', 'did', 'can', 'could', 'how',
  'what', 'where', 'when', 'why', 'who', 'which', 'with', 'this', 'that', 'there', 'please', 'tell',
  'about', 'from', 'get', 'any', 'some', 'we', 'our', 'will', 'would', 'should', 'have', 'has', 'if',
  'so', 'as', 'by', 'up', 'out', 'app', 'fandom', 'verse', 'mean', 'means', 'meaning',
};

List<String> _words(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
    .split(RegExp(r'\s+'))
    .where((w) => w.length > 1 && !_stopWords.contains(w))
    .toList();

/// A word matches another when they're equal or one starts the other with
/// at least 4 letters in common ("bookmark" ~ "bookmarks").
bool _similar(String a, String b) =>
    a == b || (a.length >= 4 && b.length >= 4 && (a.startsWith(b) || b.startsWith(a)));

int _overlap(List<String> q, Set<String> text) =>
    q.where((w) => text.any((t) => _similar(w, t))).length;

/// Offline answer: scores the question's words against FAQ questions (x3)
/// and answers (x1), and glossary terms (x4, or x6 when the whole term
/// appears in the question) and definitions (x1). The best match wins if it
/// scores at least 3 with at least one hit on an FAQ question or a term
/// name; otherwise the reply says the question needs internet.
LocalAnswer answerLocally(String question, List<Faq> faqs, List<GlossaryTerm> glossary) {
  final q = _words(question);
  final lowerQ = ' ${question.toLowerCase()} ';
  var bestScore = 0;
  String? best;
  for (final f in faqs) {
    final head = _overlap(q, _words(f.question).toSet());
    if (head == 0) continue;
    final score = head * 3 + _overlap(q, _words(f.answer).toSet());
    if (score > bestScore) {
      bestScore = score;
      best = f.answer;
    }
  }
  for (final g in glossary) {
    final termWords = _words(g.term).toSet();
    final whole = g.term.trim().isNotEmpty && lowerQ.contains(' ${g.term.toLowerCase().trim()}');
    final head = _overlap(q, termWords);
    if (head == 0 && !whole) continue;
    final score = (whole ? 6 : head * 4) + _overlap(q, _words(g.definition).toSet());
    if (score > bestScore) {
      bestScore = score;
      best = '${g.term}: ${g.definition}';
    }
  }
  if (best != null && bestScore >= 3) return LocalAnswer(best, matched: true);
  return const LocalAnswer(
    "I need an internet connection to answer that. You can also send the team a message from Contact Us.",
    matched: false,
  );
}
