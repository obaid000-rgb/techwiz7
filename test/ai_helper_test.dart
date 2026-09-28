import 'package:fandom_verse/models/faq.dart';
import 'package:fandom_verse/models/glossary_term.dart';
import 'package:fandom_verse/services/chatbot/ai_actions.dart';
import 'package:fandom_verse/services/chatbot/local_answerer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
