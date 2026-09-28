import '../models/glossary_term.dart';

final RegExp _punctuation = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
final RegExp _spaces = RegExp(r'\s+');

/// Lowercase, punctuation removed, spaces trimmed and collapsed:
/// "  ANIME  and-manga! " -> "anime and manga".
String normalizeGlossaryText(String s) =>
    s.toLowerCase().replaceAll(_punctuation, ' ').replaceAll(_spaces, ' ').trim();

/// Glossary search shared by the admin and fan Glossary screens.
///
/// The query and every field (term, definition, category display name from
/// [categoryNames]: key -> name, falling back to the key) are normalized with
/// [normalizeGlossaryText]. A term matches when the whole query appears as a
/// phrase, or when every query word appears somewhere in its fields in any
/// order ("manga anime" finds "Anime and Manga").
///
/// Ranking: exact term name, then term name starting with the query, then
/// the phrase inside the term name, then all words in the term name, then
/// matches only in the definition or category; alphabetical in each group.
/// An empty query returns every term alphabetically.
List<GlossaryTerm> filterGlossary(
  List<GlossaryTerm> terms,
  String query,
  Map<String, String> categoryNames,
) {
  int byName(GlossaryTerm a, GlossaryTerm b) =>
      a.term.toLowerCase().compareTo(b.term.toLowerCase());
  final q = normalizeGlossaryText(query);
  if (q.isEmpty) return List.of(terms)..sort(byName);
  final words = q.split(' ');

  int? rank(GlossaryTerm t) {
    final name = normalizeGlossaryText(t.term);
    if (name == q) return 0;
    if (name.startsWith(q)) return 1;
    if (name.contains(q)) return 2;
    if (words.every(name.contains)) return 3;
    final all = '$name ${normalizeGlossaryText(t.definition)} '
        '${normalizeGlossaryText(categoryNames[t.category] ?? t.category)}';
    if (all.contains(q) || words.every(all.contains)) return 4;
    return null;
  }

  final ranked = <(int, GlossaryTerm)>[
    for (final t in terms)
      if (rank(t) case final r?) (r, t),
  ]..sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : byName(a.$2, b.$2));
  return [for (final r in ranked) r.$2];
}
