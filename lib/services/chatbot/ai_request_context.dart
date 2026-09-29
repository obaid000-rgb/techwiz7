import 'ai_assistant_knowledge.dart';
import 'ai_context_builder.dart';

/// Picks what ONE Gemini request carries. Sending the whole app snapshot
/// with every question (~10k tokens) made requests slow and hit the free
/// tier's limits, so each request now gets only:
///  - the fixed rules (always),
///  - the feature-guide sections the question is about,
///  - the live content whose names match the question (plus a few trending
///    fandoms and the next events),
///  - the business facts (short, always),
///  - the fan's own account ONLY when the question is about it.
/// The last two user questions are searched too, so follow-ups like
/// "Which one is cheapest?" keep their subject.

/// Words that carry no meaning for matching.
const _stopwords = {
  'the', 'and', 'for', 'are', 'is', 'am', 'was', 'were', 'be', 'been', 'what', 'whats', 'how', 'where',
  'when', 'which', 'who', 'why', 'can', 'could', 'do', 'does', 'did', 'you', 'your', 'me', 'my', 'mine',
  'it', 'its', 'to', 'of', 'in', 'on', 'at', 'an', 'a', 'or', 'with', 'about', 'from', 'get', 'any',
  'some', 'we', 'our', 'will', 'would', 'should', 'have', 'has', 'if', 'this', 'that', 'there', 'these',
  'those', 'i', 'im', 'show', 'tell', 'find', 'give', 'list', 'please', 'want', 'need', 'one', 'ones',
  'app', 'fandom', 'verse', 'much', 'many', 'more', 'most', 'all', 'here', 'now', 'also', 'up',
  'out', 'use', 'using', 'see', 'go', 'like', 'know', 'mean', 'means', 'meaning',
};

/// Lower-case meaningful words of [text], with a simple plural fold
/// ("events" → "event") so singular and plural match.
Set<String> aiWords(String text) {
  final out = <String>{};
  for (var w in text.toLowerCase().split(RegExp(r"[^a-z0-9]+"))) {
    if (w.length < 2 || _stopwords.contains(w)) continue;
    if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss')) w = w.substring(0, w.length - 1);
    out.add(w);
  }
  return out;
}

/// All words of [text] (stopwords kept), for detecting what kind of
/// question it is.
Set<String> _rawWords(String text) =>
    text.toLowerCase().split(RegExp(r"[^a-z0-9]+")).where((w) => w.isNotEmpty).toSet();

bool _any(Set<String> words, Set<String> keys) => words.any(keys.contains);

// ── Question kinds ─────────────────────────────────────────────────────────

const _accountWords = {
  'my', 'mine', 'level', 'levels', 'xp', 'order', 'orders', 'cart', 'wishlist', 'agenda', 'saved',
  'follow', 'follows', 'following', 'followed', 'account', 'profile', 'badge', 'unlock', 'unlocked',
  'locked', 'progress', 'interests', 'deep', 'dive', 'bookmarks', 'rank',
};
const _eventWords = {
  'event', 'events', 'con', 'cons', 'convention', 'conventions', 'meetup', 'meetups', 'concert',
  'screening', 'tournament', 'week', 'weekend', 'today', 'tomorrow', 'tonight', 'near', 'nearby',
  'happening', 'upcoming', 'ticket', 'tickets', 'calendar', 'map', 'live', 'month',
};
const _shopWords = {
  'shop', 'buy', 'product', 'products', 'merch', 'merchandise', 'price', 'prices', 'cheap', 'cheapest',
  'cost', 'costs', 'store', 'sale', 'deal', 'dollar', 'dollars', 'expensive', 'budget', 'under',
};
const _cheapWords = {'cheap', 'cheapest', 'budget', 'under', 'affordable', 'lowest'};
const _trendingWords = {'trending', 'popular', 'hot', 'top', 'best', 'viral', 'recommend', 'suggest'};
const _creatorWords = {'creator', 'creators', 'writer', 'writers', 'author', 'authors', 'artist', 'artists'};

// ── Limits ─────────────────────────────────────────────────────────────────

/// Target size of the system instruction. With up to 8 history messages
/// the whole request stays under about 6,000 tokens (~4 chars per token).
const int kMaxInstructionChars = 18000;

const _caps = {
  'event': 8,
  'product': 8,
  'fandom': 5,
  'post': 5,
  'creator': 3,
  'faq': 3,
  'glossary': 4,
};

const _headers = {
  'fandom': 'FANDOMS (id | name | category | followers | trending | tags | about):',
  'creator': 'CREATORS (id | name | kind | verified | fandoms):',
  'event': 'EVENTS — upcoming and happening now, soonest first '
      '(id | title | type | status | city | venue | when | fandoms | price | ticket link):',
  'product': 'SHOP PRODUCTS (id | name | category | fandom | price):',
  'post': 'POSTS (id | title | type | fandom | creator | depth | summary):',
  'faq': 'FAQS (official answers from the Fandom Verse team; treat as correct):',
  'glossary': 'GLOSSARY (term | category | meaning):',
};

/// The system instruction for [question]. [recent] holds the previous user
/// questions (newest last) so follow-ups keep their subject.
String buildRequestInstruction(AiContext ctx, String question,
    {List<String> recent = const [], DateTime? now}) {
  final text = [...recent.length > 2 ? recent.sublist(recent.length - 2) : recent, question].join(' ');
  final words = aiWords(text);
  final raw = _rawWords(text);

  final accountPart = !ctx.signedIn
      ? AccountPart.guest
      : !_any(raw, _accountWords)
          ? AccountPart.notNeeded
          : (ctx.account == null ? AccountPart.unavailable : AccountPart.included);

  for (var scale = 1.0; ; scale /= 2) {
    final out = assembleSystemInstruction(
      today: now ?? DateTime.now(),
      accountPart: accountPart,
      account: ctx.account,
      business: ctx.business,
      guide: _guideFor(words, raw, full: scale == 1.0),
      snapshot: _snapshotFor(ctx, words, raw, scale),
    );
    // Too long (very long follow-up chains or huge matches): halve the
    // content caps until it fits.
    if (out.length <= kMaxInstructionChars || scale < 0.2) return out;
  }
}

/// Feature-guide sections for this question: the three best matches plus
/// "Navigation" and the "Not in the app" line. When nothing matches (a
/// general "what can this app do?"), the whole guide (~3k tokens) is sent.
String _guideFor(Set<String> words, Set<String> raw, {required bool full}) {
  final sections = kGuideSections;
  int score(({String title, String body}) s) {
    final t = aiWords(s.title);
    var n = 0;
    for (final w in words) {
      if (t.contains(w)) n += 3;
    }
    final b = aiWords(s.body);
    for (final w in words) {
      if (b.contains(w)) n += 1;
    }
    // Question kinds point at their sections even when the exact words
    // don't appear there.
    if (_any(raw, _eventWords) && s.title.startsWith('Events')) n += 3;
    if (_any(raw, _shopWords) && s.title.startsWith('Shop')) n += 3;
    if (_any(raw, _accountWords) &&
        (s.title.startsWith('Deep Dive') || s.title.startsWith('Profile'))) {
      n += 2;
    }
    return n;
  }

  final ranked = [for (final s in sections) (s: s, n: score(s))]..sort((a, b) => b.n.compareTo(a.n));
  final picked = ranked.where((r) => r.n >= 2).take(3).map((r) => r.s).toSet();
  if (picked.isEmpty) return full ? kFeatureGuide : 'FEATURE GUIDE\n${sections.first.body}';
  for (final s in sections) {
    if (s.title == 'Navigation' || s.title.startsWith('Not in the app')) picked.add(s);
  }
  return 'FEATURE GUIDE (the sections relevant to this question)\n\n'
      '${[for (final s in sections) if (picked.contains(s)) s.body].join('\n\n')}';
}

/// Live content for this question: matching entries of each kind (best
/// first, capped), filled with sensible defaults when the question is about
/// a kind of thing but names nothing specific ("any events this week?").
String _snapshotFor(AiContext ctx, Set<String> words, Set<String> raw, double scale) {
  int cap(String kind) => (_caps[kind]! * scale).ceil();
  final byKind = <String, List<AiEntry>>{};

  // Score every entry: a name word counts 3, any other word 1.
  final scored = <(AiEntry, int)>[];
  for (final e in ctx.entries) {
    var n = 0;
    for (final w in words) {
      if (e.nameWords.contains(w)) {
        n += 3;
      } else if (e.otherWords.contains(w)) {
        n += 1;
      }
    }
    // FAQs/glossary need a real name match; a shared common word isn't enough.
    if ((e.kind == 'faq' || e.kind == 'glossary') && n < 3) continue;
    if (n > 0) scored.add((e, n));
  }
  // Stable sort keeps each kind's priority order (soonest event, trending
  // fandom…) among equal scores.
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  for (final (e, _) in scored) {
    final list = byKind.putIfAbsent(e.kind, () => []);
    if (list.length < cap(e.kind)) list.add(e);
  }

  List<AiEntry> firstOf(String kind) => ctx.entries.where((e) => e.kind == kind).take(cap(kind)).toList();
  if (_any(raw, _eventWords) && (byKind['event']?.isEmpty ?? true)) byKind['event'] = firstOf('event');
  if (_any(raw, _shopWords) && (byKind['product']?.isEmpty ?? true)) {
    final products = ctx.entries.where((e) => e.kind == 'product').toList();
    if (_any(raw, _cheapWords)) products.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
    byKind['product'] = products.take(cap('product')).toList();
  }
  if (_any(raw, _trendingWords) && (byKind['post']?.isEmpty ?? true)) byKind['post'] = firstOf('post');
  if (_any(raw, _creatorWords) && (byKind['creator']?.isEmpty ?? true)) byKind['creator'] = firstOf('creator');

  final b = StringBuffer();
  if (ctx.categories.isNotEmpty) b.writeln('CATEGORIES (id | name):\n${ctx.categories}\n');
  final shownLines = <String>{};
  for (final kind in _headers.keys) {
    final list = byKind[kind];
    if (list == null || list.isEmpty) continue;
    b.writeln(_headers[kind]);
    for (final e in list) {
      b.writeln(e.line);
      shownLines.add(e.line);
    }
    b.writeln();
  }
  // Always a little context: what's trending and what's on next.
  final trending = ctx.trendingFandomLines.where((l) => !shownLines.contains(l)).take(4).toList();
  if (trending.isNotEmpty) b.writeln('TRENDING FANDOMS (same columns as FANDOMS):\n${trending.join('\n')}\n');
  final next = ctx.upcomingEventLines.where((l) => !shownLines.contains(l)).take(4).toList();
  if (next.isNotEmpty) b.writeln('NEXT EVENTS (same columns as EVENTS):\n${next.join('\n')}\n');
  if (b.isEmpty) b.writeln('(Nothing in the app matched this question.)');
  return b.toString().trimRight();
}
