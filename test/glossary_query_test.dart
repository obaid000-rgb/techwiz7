import 'package:fandom_verse/logic/glossary_query.dart';
import 'package:fandom_verse/models/glossary_term.dart';
import 'package:flutter_test/flutter_test.dart';

GlossaryTerm g(String term, String definition, [String category = '']) =>
    GlossaryTerm(id: term, term: term, definition: definition, category: category);

void main() {
  final terms = [
    g('Anime and Manga', 'Japanese animation and comics, often discussed together.'),
    g('Anime', 'Japanese animation.', 'anime_and_manga'),
    g('Manga', 'Japanese comics read right to left.', 'anime_and_manga'),
    g('Shipping', 'Wanting two characters to be in a relationship.'),
    g('Canon', 'What officially happens in the story.'),
    g('Cosplay', 'Dressing up as a character.', 'events'),
    g('Fanfic', 'Stories fans write about a series.'),
    g('Isekai', 'A story where someone is transported to another world, common in anime.'),
  ];
  const names = {'anime_and_manga': 'Anime and manga', 'events': 'Conventions'};
  List<String> q(String s) => filterGlossary(terms, s, names).map((t) => t.term).toList();

  test('a single full keyword', () {
    expect(q('shipping'), ['Shipping']);
    expect(q('anime').first, 'Anime'); // exact name first
  });

  test('a full multi-word name, found first', () {
    expect(q('anime and manga').first, 'Anime and Manga');
  });

  test('words in a different order', () {
    expect(q('manga anime').first, 'Anime and Manga');
  });

  test('phrase match inside a longer text', () {
    expect(q('right to left'), ['Manga']);
  });

  test('definition-only match', () {
    expect(q('relationship'), ['Shipping']);
  });

  test('category display-name match', () {
    expect(q('conventions'), ['Cosplay']);
  });

  test('extra spaces, capitals and punctuation', () {
    expect(q('ANIME  and manga').first, 'Anime and Manga');
    expect(q('  anime-and-manga!! ').first, 'Anime and Manga');
    expect(q('"Canon"'), ['Canon']);
  });

  test('empty query returns every term alphabetically', () {
    expect(q(''), ['Anime', 'Anime and Manga', 'Canon', 'Cosplay', 'Fanfic', 'Isekai', 'Manga', 'Shipping']);
    expect(q('   ...  '), q(''));
  });

  test('ranking: exact, starts with, phrase in name, words in name, then definition/category', () {
    // "anime": exact "Anime", then "Anime and Manga" (starts with), then the
    // definition/category-only matches (Isekai via its definition, Manga via
    // its category name), alphabetical.
    expect(q('anime'), ['Anime', 'Anime and Manga', 'Isekai', 'Manga']);
    // "manga": exact, then phrase inside a name, then category-only match.
    expect(q('manga'), ['Manga', 'Anime and Manga', 'Anime']);
    // "manga anime": all words in the name beat category-only matches.
    expect(q('manga anime'), ['Anime and Manga', 'Anime', 'Manga']);
  });

  test('no match returns nothing', () {
    expect(q('zzz'), isEmpty);
  });
}
