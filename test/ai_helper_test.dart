import 'package:fandom_verse/models/faq.dart';
import 'package:fandom_verse/models/glossary_term.dart';
import 'package:fandom_verse/services/chatbot/ai_actions.dart';
import 'package:fandom_verse/services/chatbot/ai_context_builder.dart';
import 'package:fandom_verse/services/chatbot/ai_request_context.dart';
import 'package:fandom_verse/services/chatbot/local_answerer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('per-question context', () {
    final entries = [
      AiEntry('event', '- e1 | Karachi Comic Con | Convention | Karachi', 'Karachi Comic Con', 'Karachi Expo'),
      AiEntry('event', '- e2 | Lahore Gaming Fest | Convention | Lahore', 'Lahore Gaming Fest', 'Lahore Expo'),
      for (var i = 0; i < 60; i++)
        AiEntry('product', '- p$i | Naruto Hoodie $i | \$${20 + i}', 'Naruto Hoodie $i', 'Naruto', price: 20.0 + i),
      for (var i = 0; i < 200; i++)
        AiEntry('glossary', '- Term$i | Anime | A fan word number $i.', 'Term$i', 'Anime'),
      AiEntry('glossary', '- Shipping | Anime | Wanting two characters together.', 'Shipping', 'Anime'),
    ];
    AiContext ctx({bool signedIn = true}) => AiContext(
          builtAt: DateTime(2026, 9, 29),
          uid: signedIn ? 'u1' : null,
          signedIn: signedIn,
          account: signedIn ? 'Level: 2 (Fan), XP: 150' : null,
          entries: entries,
        );

    test('only matching content is sent', () {
      final s = buildRequestInstruction(ctx(), 'What events are in Karachi this week?');
      expect(s, contains('Karachi Comic Con'));
      expect(s, isNot(contains('Lahore Gaming Fest')));
      expect(s, isNot(contains('Naruto Hoodie')));
      expect(s, isNot(contains('Term5 |')));
    });

    test('a follow-up keeps the earlier subject', () {
      final s = buildRequestInstruction(ctx(), 'Which one is cheapest?',
          recent: ['What events are in Karachi this week?']);
      expect(s, contains('Karachi Comic Con'));
    });

    test('account data only for questions about the account', () {
      expect(buildRequestInstruction(ctx(), 'What level am I?'), contains('XP: 150'));
      final other = buildRequestInstruction(ctx(), 'What does shipping mean?');
      expect(other, isNot(contains('XP: 150')));
      expect(other, contains('Wanting two characters together'));
      expect(buildRequestInstruction(ctx(signedIn: false), 'What level am I?'), contains('GUEST'));
    });

    test('cheap shop questions get the cheapest products, within the size limit', () {
      final s = buildRequestInstruction(ctx(), 'show me cheap merch');
      expect(s, contains('Naruto Hoodie 0 |'));
      expect(s, isNot(contains('Naruto Hoodie 59 |')));
      expect(s.length, lessThanOrEqualTo(kMaxInstructionChars));
    });
  });

  group('action tags', () {
    const known = {'fandom:naruto': 'Open Naruto', 'event:ev1': 'Open Lahore Comic Con'};
    String? labelFor(String kind, String id) => known['$kind:$id'];

    test('valid tags become buttons with real names; text is stripped', () {
      const raw = 'Naruto is trending.\n[[open:fandom:naruto]] [[open:event:ev1]]';
      final actions = parseActionTags(raw, labelFor);
      expect(actions.map((a) => a.label), ['Open Naruto', 'Open Lahore Comic Con']);
      expect(stripActionTags(raw), 'Naruto is trending.');
    });

    test('made-up ids, unknown kinds and unknown screens are dropped', () {
      const raw = '[[open:fandom:madeup]] [[open:spaceship:x]] [[open:screen:settings]] [[open:screen:cart]]';
      final actions = parseActionTags(raw, labelFor);
      expect(actions.map((a) => '${a.kind}:${a.id}'), ['screen:cart']);
      expect(actions.single.label, 'View cart');
      expect(stripActionTags(raw), '');
    });

    test('at most 3, no duplicates, spaces tolerated', () {
      const raw = '[[open:screen:cart]][[open:screen:cart]][[ open : screen : wishlist ]]'
          '[[open:screen:glossary]][[open:screen:contact]]';
      expect(parseActionTags(raw, labelFor).map((a) => a.id), ['cart', 'wishlist', 'glossary']);
    });

    test('a half-written tag is hidden while streaming', () {
      expect(stripActionTags('See the events. [[open:ev'), 'See the events.');
      expect(stripActionTags('Plain text'), 'Plain text');
    });
  });

  group('local (offline) answers', () {
    final faqs = [
      Faq(
          id: '1',
          question: 'How do I save a post to read offline?',
          answer: 'Tap the bookmark icon on a post. Bookmarked posts are saved on your phone.',
          createdAt: DateTime(2026)),
      Faq(
          id: '2',
          question: 'Is checkout real?',
          answer: 'No, checkout is simulated. No payment is taken.',
          createdAt: DateTime(2026)),
    ];
    final glossary = [
      const GlossaryTerm(id: 'g1', term: 'Shipping', definition: 'Wanting two characters to be in a relationship.'),
      const GlossaryTerm(id: 'g2', term: 'Canon', definition: 'What officially happens in the story.'),
    ];

    test('an FAQ question gets its answer', () {
      final a = answerLocally('how can I save posts offline?', faqs, glossary);
      expect(a.matched, isTrue);
      expect(a.text, startsWith('Tap the bookmark icon'));
      expect(answerLocally('is the checkout real', faqs, glossary).text, contains('simulated'));
    });

    test('a glossary term gets its definition', () {
      final a = answerLocally('What does shipping mean?', faqs, glossary);
      expect(a.matched, isTrue);
      expect(a.text, 'Shipping: Wanting two characters to be in a relationship.');
    });

    test('no good match says it needs internet', () {
      final a = answerLocally('who won the match yesterday', faqs, glossary);
      expect(a.matched, isFalse);
      expect(a.text, contains('internet'));
      expect(a.text, contains('Contact Us'));
    });
  });
}
