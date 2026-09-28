// Tag normalization — the one rule every tag goes through before it is
// stored or compared (posts, fandoms, the tags collection, search):
//   1. lowercase and trim
//   2. every run of whitespace becomes a single hyphen
//   3. drop anything that is not a–z, 0–9 or a hyphen
//   4. collapse repeated hyphens, then trim hyphens from both ends
// So "  Season Finale!! " → "season-finale" and "Patch  Notes" →
// "patch-notes". The result doubles as the tags/{slug} document ID.
String normalizeTag(String raw) => raw
    .toLowerCase()
    .trim()
    .replaceAll(RegExp(r'\s+'), '-')
    .replaceAll(RegExp(r'[^a-z0-9-]'), '')
    .replaceAll(RegExp(r'-+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

List<String> normalizeTags(Iterable<String> raw) {
  final out = <String>[];
  for (final t in raw) {
    final tag = normalizeTag(t);
    if (tag.isNotEmpty && !out.contains(tag)) out.add(tag);
  }
  return out;
}
