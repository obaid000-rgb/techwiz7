import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../config/app_info.dart';
import '../../logic/event_status.dart';
import '../../models/app_category.dart';
import '../../models/cart_item.dart';
import '../../models/creator.dart';
import '../../models/event_item.dart';
import '../../models/faq.dart';
import '../../models/fandom.dart';
import '../../models/glossary_term.dart';
import '../../models/merchandise.dart';
import '../../models/order_model.dart';
import '../../models/post.dart';
import '../../models/team_member.dart';
import '../../utils/event_format.dart';
import '../../utils/fandom_stats.dart';
import '../../utils/levels.dart';
import '../auth_service.dart';
import '../cart_service.dart';
import '../event_service.dart';
import '../faq_service.dart';
import '../glossary_service.dart';
import '../merchandise_service.dart';
import '../order_service.dart';
import '../resource_repository.dart';
import '../saved_event_store.dart';
import '../team_service.dart';
import 'ai_assistant_knowledge.dart';

/// Everything the assistant knows for one chat, assembled on the device.
class AiContext {
  final String systemInstruction;
  final DateTime builtAt;
  final String? uid;
  // Lookups for action buttons: an action tag is only shown when its id is
  // here, and these objects are what the buttons navigate to.
  final Map<String, Fandom> fandoms;
  final Map<String, EventItem> events;
  final Map<String, Merchandise> products;
  final Map<String, Post> posts;
  final Map<String, Creator> creators;
  final Map<String, AppCategory> categories;
  // Kept for the offline (local) answers.
  final List<Faq> faqs;
  final List<GlossaryTerm> glossary;
  // For the starter suggestions.
  final bool hasFollows;
  final bool hasCart;
  final bool hasOrders;
  final bool atMaxLevel;

  const AiContext({
    required this.systemInstruction,
    required this.builtAt,
    required this.uid,
    this.fandoms = const {},
    this.events = const {},
    this.products = const {},
    this.posts = const {},
    this.creators = const {},
    this.categories = const {},
    this.faqs = const [],
    this.glossary = const [],
    this.hasFollows = false,
    this.hasCart = false,
    this.hasOrders = false,
    this.atMaxLevel = false,
  });

  /// Rough size of the system instruction in tokens (about 4 characters
  /// per token for English text).
  int get approxTokens => (systemInstruction.length / 4).round();
}

/// Builds the assistant's system instruction from three sources:
///  1. the feature guide (written from the app's screens, in
///     ai_assistant_knowledge.dart);
///  2. a compact snapshot of the app's live content;
///  3. the signed-in fan's own account (nothing for guests, never anyone
///     else's data).
/// The result is cached for 10 minutes per account.
class AiContextBuilder {
  static final AiContextBuilder instance = AiContextBuilder._();
  AiContextBuilder._();

  static const cacheFor = Duration(minutes: 10);

  // ── Snapshot size limits ─────────────────────────────────────────────────
  // The whole system instruction must stay under ~25,000 tokens (~100,000
  // characters). Lists are capped first; if the text is still too long,
  // descriptions are shortened step by step (see [_compose]).
  static const maxEvents = 40;
  static const maxProducts = 60;
  static const maxNewestPosts = 40;
  static const maxTrendingPosts = 10;
  static const maxChars = 100000;

  AiContext? _cache;

  AiContext? get cached => _cache;

  void invalidate() => _cache = null;

  Future<AiContext> get({bool force = false}) async {
    final uid = AuthService.instance.currentUser?.uid;
    final c = _cache;
    if (!force && c != null && c.uid == uid && DateTime.now().difference(c.builtAt) < cacheFor) {
      return c;
    }
    return _cache = await _build();
  }

  /// Runs [load] with a time limit; a failed or slow source is left out
  /// instead of failing the whole context (offline, Firestore serves its
  /// cache where it has one).
  Future<T> _safe<T>(Future<T> load, T fallback) async {
    try {
      return await load.timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[AiContext] source skipped: $e');
      return fallback;
    }
  }

  Future<AiContext> _build() async {
    final now = DateTime.now();
    final user = AuthService.instance.currentUser;

    final resourcesF = _safe<ResourceData?>(const FirestoreResourceRepository().loadAll(), null);
    final eventsF = _safe(EventService.instance.watchUpcomingEvents().first, const <EventItem>[]);
    final productsF = _safe(MerchandiseService.instance.watchMerchandise().first, const <Merchandise>[]);
    final glossaryF = _safe(GlossaryService.instance.watchTerms().first, const <GlossaryTerm>[]);
    final faqsF = _safe(FaqService.instance.fetchActive(), const <Faq>[]);
    final teamF = _safe(TeamService.instance.watchAll().first, const <TeamMember>[]);
    final cartF = user == null
        ? Future.value(const <CartItem>[])
        : _safe(CartService.instance.watchCart(user.uid).first, const <CartItem>[]);
    final ordersF = user == null
        ? Future.value(const <OrderModel>[])
        : _safe(OrderService.instance.watchUserOrders(user.uid).first, const <OrderModel>[]);
    final savedF = user == null
        ? Future.value(const <SavedEventEntry>[])
        : _safe(SavedEventStore.instance.entriesFor(user.uid), const <SavedEventEntry>[]);

    final resources = await resourcesF;
    final events = (await eventsF).where((e) => e.isVisibleToFans(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final products = await productsF;
    final glossary = await glossaryF;
    final faqs = await faqsF;
    final team = await teamF;
    final cart = await cartF;
    final orders = await ordersF;
    final saved = await savedF;

    final categories = resources?.categories ?? const <AppCategory>[];
    final fandoms = resources?.fandoms ?? const <Fandom>[];
    final creators = (resources?.creators ?? const <Creator>[]).where((c) => c.isActive).toList();
    final posts = (resources?.posts ?? const <Post>[]).where((p) => p.isActive).toList();

    final shownEvents = events.take(maxEvents).toList();
    final shownProducts = products.take(maxProducts).toList();
    final newest = List.of(posts)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    int todayViews(Post p) => p.todayViewDate == today ? p.todayViewCount : 0;
    final trending = List.of(posts)
      ..sort((a, b) {
        final t = todayViews(b).compareTo(todayViews(a));
        return t != 0 ? t : b.viewCount.compareTo(a.viewCount);
      });
    final shownPosts = <String, Post>{
      for (final p in newest.take(maxNewestPosts)) p.id: p,
      for (final p in trending.take(maxTrendingPosts))
        if (todayViews(p) > 0 || p.viewCount > 0) p.id: p,
    };
    final trendingPostIds = {
      for (final p in trending.take(maxTrendingPosts))
        if (todayViews(p) > 0 || p.viewCount > 0) p.id,
    };

    final data = _Data(
      now: now,
      categories: categories,
      fandoms: fandoms,
      trendingFandomIds: {
        for (final f in rankTrendingFandoms(fandoms, now, limit: 8, fallbackToMostFollowed: false)) f.id,
      },
      creators: creators,
      events: shownEvents,
      products: shownProducts,
      posts: shownPosts.values.toList(),
      trendingPostIds: trendingPostIds,
      faqs: faqs,
      team: team,
      glossary: glossary,
      user: user,
      cart: cart,
      orders: orders,
      saved: saved,
    );
    final instruction = _compose(data);

    return AiContext(
      systemInstruction: instruction,
      builtAt: now,
      uid: user?.uid,
      fandoms: {for (final f in fandoms) f.id: f},
      events: {for (final e in shownEvents) e.id: e},
      products: {for (final p in shownProducts) p.id: p},
      posts: shownPosts,
      creators: {for (final c in creators) c.id: c},
      categories: {for (final c in categories) c.key: c},
      faqs: faqs,
      glossary: glossary,
      hasFollows: (user?.followedFandomIds.isNotEmpty ?? false),
      hasCart: cart.isNotEmpty,
      hasOrders: orders.isNotEmpty,
      atMaxLevel: user != null && levelFor(user.xp) >= kMaxLevel,
    );
  }

  /// Builds the instruction, shortening descriptions until it fits
  /// [maxChars]: step 0 full, then one-line texts cut to 120, 70 and 40
  /// characters, then glossary definitions dropped to their first words.
  /// Who runs the app and how to reach them: the same facts About Us and
  /// Contact Us show. Unpublished details are marked so the helper never
  /// invents an email, phone or address.
  String _business(_Data d) {
    const notYet = 'not published yet (use the "Send an Inquiry" form in Contact Us)';
    final b = StringBuffer()
      ..writeln('- Name: ${AppInfo.appName} – ${AppInfo.edition}. Tagline: "${AppInfo.tagline}"')
      ..writeln('- Run by: ${AppInfo.teamName}.')
      ..writeln('- Our story: ${AppInfo.story}')
      ..writeln('- Mission: ${AppInfo.mission}')
      ..writeln('- Support email: ${AppInfo.supportEmail ?? notYet}')
      ..writeln('- Phone: ${AppInfo.phone ?? notYet}')
      ..writeln('- Working hours: ${AppInfo.workingHours ?? 'not published yet'}')
      ..writeln('- Office: ${AppInfo.officeAddress ?? 'not published yet'}'
          '${AppInfo.hasOfficeCoordinates ? ' (on the map in Contact Us, with "Get Directions")' : ''}')
      ..writeln('- To reach the team: Contact Us > "Send an Inquiry"; the team reads every message.')
      ..writeln('- The team (About Us > "Meet the Team"):');
    for (final m in d.team) {
      b.writeln('  - ${m.name}${m.role.isEmpty ? '' : ' — ${m.role}'}${m.bio.isEmpty ? '' : ': ${_cut(m.bio, 200)}'}');
    }
    if (d.team.isEmpty) b.writeln('  - (not introduced yet)');
    return b.toString().trimRight();
  }

  String _compose(_Data d) {
    for (var level = 0; level < 5; level++) {
      final text = assembleSystemInstruction(
        today: d.now,
        account: _account(d),
        business: _business(d),
        snapshot: _snapshot(d, level),
      );
      if (text.length <= maxChars || level == 4) return text;
    }
    throw StateError('unreachable');
  }

  static String _cut(String s, int max) {
    final one = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return one.length <= max ? one : '${one.substring(0, max).trimRight()}…';
  }

  String _snapshot(_Data d, int level) {
    final lineMax = const [200, 120, 70, 40, 30][level];
    final glossMax = const [220, 140, 90, 50, 30][level];
    final b = StringBuffer();
    final catName = {for (final c in d.categories) c.key: c.name};
    final fandomName = {for (final f in d.fandoms) f.id: f.name};
    String names(List<String> ids) =>
        ids.map((id) => fandomName[id]).whereType<String>().join(', ');
    String money(double v) => '\$${v.toStringAsFixed(2)}';

    b.writeln('CATEGORIES (id | name):');
    for (final c in d.categories) {
      b.writeln('- ${c.key} | ${c.name}');
    }

    b.writeln('\nFANDOMS (id | name | category | followers | trending | tags | about):');
    for (final f in d.fandoms) {
      b.writeln('- ${f.id} | ${f.name} | ${catName[f.categoryId] ?? f.categoryName} | '
          '${formatCount(f.followerCount)} | ${d.trendingFandomIds.contains(f.id) ? 'TRENDING' : '-'} | '
          '${f.tags.join(', ')} | ${_cut(f.description, lineMax)}');
    }

    b.writeln('\nCREATORS (id | name | kind | verified | fandoms):');
    for (final c in d.creators) {
      b.writeln('- ${c.id} | ${c.name} | ${kCreatorKindLabels[c.kind] ?? c.kind} | '
          '${c.isVerified ? 'verified' : '-'} | ${names(c.fandomIds)}');
    }

    b.writeln('\nEVENTS — upcoming and happening now, soonest first, up to $maxEvents '
        '(id | title | type | status | city | venue | when | fandoms | price | ticket link):');
    for (final e in d.events) {
      final status = eventStatusLabel(e.statusAt(d.now));
      b.writeln('- ${e.id} | ${e.title} | ${e.eventType.label} | $status | ${e.city} | ${e.venue} | '
          '${formatEventRange(e.date, e.endAt, now: d.now)} | ${names(e.fandomIds)} | '
          '${e.ticketPrice.isEmpty ? 'Free / not set' : e.ticketPrice} | '
          '${e.ticketLink.isEmpty ? 'no' : 'yes'}');
    }
    if (d.events.isEmpty) b.writeln('- (no upcoming events)');

    b.writeln('\nSHOP PRODUCTS — up to $maxProducts (id | name | category | fandom | price):');
    for (final p in d.products) {
      b.writeln('- ${p.id} | ${p.name} | ${catName[p.category] ?? p.category} | '
          '${p.fandomName.isEmpty ? '-' : p.fandomName} | ${money(p.price)}');
    }
    if (d.products.isEmpty) b.writeln('- (no products)');

    // Deep Dive exclusion: Deep Dive posts are listed with their title and
    // fandom ONLY. Their body is never put in the context, so the model
    // cannot reveal it to anyone, whatever their level.
    b.writeln('\nPOSTS — newest $maxNewestPosts plus the most viewed '
        '(id | title | type | fandom | creator | depth | summary):');
    for (final p in d.posts) {
      final deep = p.contentDepth == 'deep';
      final depth = deep ? 'DEEP DIVE (Level $kDeepDiveLevel)' : (p.contentDepth == 'beginner' ? 'beginner' : 'standard');
      final summary = deep ? '(locked — content not available to you)' : _cut(p.content, lineMax);
      final hot = d.trendingPostIds.contains(p.id) ? ' [most viewed]' : '';
      b.writeln('- ${p.id} | ${p.title}$hot | ${p.contentType} | '
          '${p.fandomName.isEmpty ? '-' : p.fandomName} | ${p.creatorName.isEmpty ? '-' : p.creatorName} | '
          '$depth | $summary');
    }

    b.writeln('\nFAQS (official answers from the Fandom Verse team; treat as correct):');
    for (final f in d.faqs) {
      b.writeln('Q: ${f.question}');
      b.writeln('A: ${_cut(f.answer, level == 0 ? 1000 : glossMax * 2)}');
    }
    if (d.faqs.isEmpty) b.writeln('- (none)');

    b.writeln('\nGLOSSARY (term | category | meaning):');
    for (final g in d.glossary) {
      b.writeln('- ${g.term} | ${catName[g.category] ?? (g.category.isEmpty ? 'General' : g.category)} | '
          '${_cut(g.definition, glossMax)}');
    }
    return b.toString();
  }

  /// The signed-in fan's own data only; null for guests.
  String? _account(_Data d) {
    final u = d.user;
    if (u == null) return null;
    final level = levelFor(u.xp);
    final next = xpForNextLevel(u.xp);
    final catName = {for (final c in d.categories) c.key: c.name};
    final fandomName = {for (final f in d.fandoms) f.id: f.name};
    final productName = {for (final p in d.products) p.id: p.name};
    final b = StringBuffer()
      ..writeln('Name: ${u.name.isEmpty ? '(not set)' : u.name}')
      ..writeln('Level: $level (${levelName(level)}), XP: ${u.xp}'
          '${next == null ? ' — max level' : ', ${xpToNextLevel(u.xp)} XP to Level ${level + 1} (${levelName(level + 1)}) at $next XP'}')
      ..writeln('Deep Dive: ${canOpenDeepDive(signedIn: true, isAdmin: u.isAdmin, xp: u.xp) ? 'UNLOCKED' : 'LOCKED (needs Level $kDeepDiveLevel, ${xpToLevel(u.xp, kDeepDiveLevel)} XP to go)'}')
      ..writeln('Follows: ${u.followedFandomIds.map((id) => fandomName[id] ?? id).join(', ').ifEmpty('none')}')
      ..writeln('Interests: ${u.categories.map((k) => catName[k] ?? k).join(', ').ifEmpty('none')}');
    final saved = List.of(d.saved)..sort((a, b) => a.event.date.compareTo(b.event.date));
    b.writeln('My Agenda (saved events): ${saved.isEmpty ? 'none' : ''}');
    for (final s in saved) {
      b.writeln('- ${s.event.title} | ${formatEventRange(s.event.date, s.event.endAt, now: d.now)} | '
          '${eventStatusLabel(s.event.statusAt(d.now))}${s.noLongerListed ? ' | no longer listed' : ''}');
    }
    final wish = u.wishlistedProductIds.map((id) => productName[id]).whereType<String>().toList();
    b.writeln('Wishlist: ${wish.isEmpty ? '${u.wishlistedProductIds.length} item(s)' : wish.join(', ')}');
    final items = d.cart.fold<int>(0, (n, c) => n + c.quantity);
    final total = d.cart.fold<double>(0, (t, c) => t + c.price * c.quantity);
    b.writeln('Cart: $items item(s), total \$${total.toStringAsFixed(2)}'
        '${d.cart.isEmpty ? '' : ' — ${d.cart.map((c) => '${c.quantity}× ${c.name}').join(', ')}'}');
    final orders = List.of(d.orders)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    b.writeln('Recent orders (newest first): ${orders.isEmpty ? 'none' : ''}');
    for (final o in orders.take(5)) {
      b.writeln('- ${o.displayNumber} | placed ${formatEventDay(o.createdAt, now: d.now)} | '
          'status: ${o.status} | total \$${o.total.toStringAsFixed(2)} | '
          '${o.items.map((i) => '${i.quantity}× ${i.name}').join(', ')}');
    }
    return b.toString();
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

class _Data {
  final DateTime now;
  final List<AppCategory> categories;
  final List<Fandom> fandoms;
  final Set<String> trendingFandomIds;
  final List<Creator> creators;
  final List<EventItem> events;
  final List<Merchandise> products;
  final List<Post> posts;
  final Set<String> trendingPostIds;
  final List<Faq> faqs;
  final List<TeamMember> team;
  final List<GlossaryTerm> glossary;
  final UserData? user;
  final List<CartItem> cart;
  final List<OrderModel> orders;
  final List<SavedEventEntry> saved;

  const _Data({
    required this.now,
    required this.categories,
    required this.fandoms,
    required this.trendingFandomIds,
    required this.creators,
    required this.events,
    required this.products,
    required this.posts,
    required this.trendingPostIds,
    required this.faqs,
    required this.team,
    required this.glossary,
    required this.user,
    required this.cart,
    required this.orders,
    required this.saved,
  });
}
