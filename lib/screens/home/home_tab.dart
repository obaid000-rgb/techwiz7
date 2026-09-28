import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../models/event_item.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/category_service.dart';
import '../../services/event_service.dart';
import '../../services/first_run_service.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bookmark_button.dart';
import 'widgets/fandom_heart_button.dart';
import '../../widgets/lore_card.dart';
import '../../widgets/trending_badge.dart';
import 'widgets/from_your_fandoms_section.dart';
import 'widgets/new_fan_card.dart';
import 'widgets/trending_carousel.dart';
import '../explore/category_detail_screen.dart';
import '../explore/fandom_detail_screen.dart';
import '../events/widgets/event_card.dart';

class HomeTab extends StatefulWidget {
  final String searchQuery;
  /// Clears the search box that lives in FanHomeScreen (used by "Clear filters").
  final VoidCallback? onClearSearch;
  const HomeTab({super.key, this.searchQuery = '', this.onClearSearch});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedCategory = 'all';
  String _activeDepth = 'all';

  late final Stream<List<AppCategory>> _categories =
      CategoryService.instance.watchActiveCategories();
  late final Stream<List<Post>> _posts = PostService.instance.watchActivePosts();

  // Trending Events: subscribed once and held in state rather than a
  // StreamBuilder inside the ListView, so list rebuilds never resubscribe.
  StreamSubscription<List<EventItem>>? _trendingSub;
  List<EventItem> _trendingEvents = const [];

  // "Based on your interests": a guest's picks live only in the on-device
  // first-run cache (no Firestore profile yet); a signed-in fan's come from
  // their profile (UserData.categories). Home rebuilds when either changes.
  List<String> _guestInterests = const [];

  void _onUserChanged() {
    if (AuthService.instance.currentUser == null) {
      _loadGuestInterests();
    } else if (mounted) {
      setState(() {}); // e.g. fandoms edited in Profile
    }
  }

  Future<void> _loadGuestInterests() async {
    final pending = await FirstRunService.instance.readPending();
    if (mounted) setState(() => _guestInterests = pending?.categories ?? const []);
  }

  List<String> get _interests =>
      AuthService.instance.currentUser?.categories ?? _guestInterests;

  @override
  void initState() {
    super.initState();
    AuthService.instance.userNotifier.addListener(_onUserChanged);
    _loadGuestInterests();
    _trendingSub = EventService.instance.watchTrendingEvents().listen(
      (events) {
        if (mounted) setState(() => _trendingEvents = events);
      },
      onError: (Object e) => debugPrint('Trending events load error: $e'),
    );
  }

  @override
  void dispose() {
    AuthService.instance.userNotifier.removeListener(_onUserChanged);
    _trendingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCategory>>(
      stream: _categories,
      builder: (context, catSnap) {
        final cats = List<AppCategory>.from(catSnap.data ?? [])
          ..sort((a, b) => a.order.compareTo(b.order));
        final catNames = {for (final c in cats) c.key: c.name};

        return StreamBuilder<List<Post>>(
          stream: _posts,
          builder: (context, postSnap) {
            final allPosts = postSnap.data ?? [];
            final counts = <String, int>{};
            for (final p in allPosts) {
              counts[p.category] = (counts[p.category] ?? 0) + 1;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                // New fans: "Start here" → Beginner Fan Hub (hides when done).
                const NewFanCard(),

                // Admin-curated slider stays on top.
                _sectionTitle('TRENDING FANDOMS', 'Hot right now across Fandom Verse'),
                const SizedBox(height: 12),
                const TrendingCarousel(),
                const SizedBox(height: 28),

                const FromYourFandomsSection(),

                // Admin-flagged upcoming events; the whole section is hidden
                // when none are flagged. Re-checked by day so an event that
                // passes while the app is open drops off.
                ..._trendingEventsSection(),

                // Personalised: posts from the fandoms the fan picked.
                ..._interestsSection(postSnap, allPosts, catNames),

                if (cats.isNotEmpty) ...[
                  _sectionTitle('FEATURED FANDOMS', 'Tap a fandom to see all its posts'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: cats.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) =>
                          _fandomCard(cats[i], counts[cats[i].key] ?? 0),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                _sectionTitle('LATEST POSTS', 'Pick a fandom or reading level to narrow the list'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      _chip('All', 'all'),
                      for (final c in cats) _chip(c.name, c.key),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _levelToggle(),
                const SizedBox(height: 16),
                ..._postList(postSnap, allPosts, catNames),
              ],
            );
          },
        );
      },
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  /// Newest posts from the fan's picked fandoms, shown with the shared
  /// LoreCard in a horizontal strip. Reuses Home's existing active-posts
  /// stream (the same "filter by category key" the chips and Category
  /// Detail use) — no extra query. Interests pointing at categories that
  /// no longer exist/are inactive are ignored.
  List<Widget> _interestsSection(
      AsyncSnapshot<List<Post>> postSnap, List<Post> allPosts, Map<String, String> catNames) {
    if (!postSnap.hasData || catNames.isEmpty) return const []; // still loading
    final keys = [for (final k in _interests) if (catNames.containsKey(k)) k];
    final names = [for (final k in keys) catNames[k]!];

    final String subtitle;
    final List<Widget> body;
    if (keys.isEmpty) {
      subtitle = 'Pick the fandoms you love to get a personalised feed';
      body = [
        _message(
          Icons.favorite_border,
          'No interests picked yet',
          AuthService.instance.currentUser != null
              ? 'Tap the heart on any fandom in Featured Fandoms below, or edit My Fandoms in Profile.'
              : 'Browse Featured Fandoms below, or create an account to save your favourite fandoms.',
        ),
      ];
    } else {
      final picked = keys.toSet();
      final posts = allPosts.where((p) => picked.contains(p.category)).take(8).toList();
      subtitle = 'Based on your interests: ${_joinNames(names)}';
      body = posts.isEmpty
          ? [
              _message(
                Icons.auto_stories_outlined,
                'Nothing here yet',
                'There are no posts for ${_joinNames(names)} yet. Browse other fandoms in Featured Fandoms below.',
              ),
            ]
          : [
              SizedBox(
                height: 300,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) =>
                      SizedBox(width: 270, child: LoreCard(post: posts[i])),
                ),
              ),
            ];
    }
    return [
      _sectionTitle('FOR YOU', subtitle),
      const SizedBox(height: 12),
      ...body,
      const SizedBox(height: 16),
    ];
  }

  /// "Gaming, Anime & Manga" — comma-separated (names may contain "&"),
  /// capped at three: "A, B, C and 2 more".
  static String _joinNames(List<String> names) {
    if (names.length <= 3) return names.join(', ');
    return '${names.take(3).join(', ')} and ${names.length - 3} more';
  }

  List<Widget> _trendingEventsSection() {
    // Re-checked here so an event drops off once it ends (end time, or the
    // end of its start day) even without a new snapshot.
    final events = _trendingEvents.where((e) => e.isVisibleToFans()).toList();
    if (events.isEmpty) return const [];
    return [
      _sectionTitle('TRENDING EVENTS', 'Upcoming conventions and meetups fans are talking about'),
      const SizedBox(height: 12),
      for (final e in events) EventCard(event: e),
      const SizedBox(height: 16),
    ];
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.orbitron(size: 13, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
        ],
      );

  Widget _fandomCard(AppCategory cat, int postCount) {
    final hasImage = cat.imageUrl != null && cat.imageUrl!.isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
      ),
      child: Container(
        width: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(cat.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (ctx, e, st) => _imageFallback())
            else
              _imageFallback(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xF20D0E15)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: FandomHeartButton(categoryKey: cat.key, categoryName: cat.name),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('$postCount post${postCount == 1 ? '' : 's'}',
                      style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: const Color(0xFF1C1E2E),
        alignment: Alignment.center,
        child: const Icon(Icons.auto_awesome_outlined, color: Colors.white24, size: 32),
      );

  Widget _chip(String label, String value) {
    final on = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppTheme.accent : AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? AppTheme.accent : AppTheme.border),
          ),
          child: Text(label,
              style: AppTheme.inter(
                  size: 13,
                  weight: FontWeight.w600,
                  color: on ? Colors.white : AppTheme.textSecondary)),
        ),
      ),
    );
  }

  Widget _levelToggle() {
    Widget seg(String label, String value) {
      final on = _activeDepth == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _activeDepth = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppTheme.border : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                style: AppTheme.inter(
                    size: 13,
                    weight: FontWeight.w600,
                    color: on ? Colors.white : AppTheme.textMuted)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        seg('All levels', 'all'),
        seg('Beginner', 'beginner'),
        seg('Expert', 'deep'),
      ]),
    );
  }

  List<Widget> _postList(
      AsyncSnapshot<List<Post>> snap, List<Post> allPosts, Map<String, String> catNames) {
    if (snap.hasError) {
      debugPrint('Home posts load error: ${snap.error}');
      return [
        _message(Icons.wifi_off, 'Could not load posts',
            'Check your connection and try again.'),
      ];
    }
    if (!snap.hasData) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan)),
        ),
      ];
    }
    if (allPosts.isEmpty) {
      return [
        _message(Icons.menu_book_outlined, 'No posts yet',
            'Check back soon when new content is published.'),
      ];
    }

    final q = widget.searchQuery.trim().toLowerCase();
    final filtered = allPosts.where((p) {
      if (q.isNotEmpty &&
          !p.title.toLowerCase().contains(q) &&
          !p.content.toLowerCase().contains(q)) {
        return false;
      }
      if (_activeDepth != 'all' && p.contentDepth != _activeDepth) return false;
      return _selectedCategory == 'all' || p.category == _selectedCategory;
    }).toList();

    if (filtered.isEmpty) {
      return [
        _message(
          Icons.search_off,
          q.isNotEmpty ? 'No posts match "${widget.searchQuery.trim()}"' : 'No posts for this filter',
          'Try another fandom or reading level.',
          action: 'Clear filters',
          onAction: () {
            widget.onClearSearch?.call();
            setState(() {
              _selectedCategory = 'all';
              _activeDepth = 'all';
            });
          },
        ),
      ];
    }
    return [for (final p in filtered) _postRow(p, catNames[p.category] ?? p.category)];
  }

  Widget _postRow(Post post, String fandomName) {
    final level = switch (post.contentDepth) {
      'beginner' => 'Beginner',
      'deep' => 'Expert',
      _ => post.contentType,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FandomDetailScreen(post: post)),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: PostMediaThumbnail(post: post, height: 84, playIconSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrendingBadge(postId: post.id, margin: const EdgeInsets.only(bottom: 6)),
                      Text(
                        fandomName.isEmpty ? level : '$fandomName · $level',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 11, weight: FontWeight.w600, color: AppTheme.cyan),
                      ),
                      const SizedBox(height: 5),
                      Text(post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 14, weight: FontWeight.w600, height: 1.3)),
                      const SizedBox(height: 5),
                      Text(_relativeDate(post.createdAt),
                          style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                BookmarkButton(post: post),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _message(IconData icon, String title, String subtitle,
          {String? action, VoidCallback? onAction}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.textMuted, size: 36),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTheme.inter(size: 15, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
            if (action != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onAction,
                child: Text(action,
                    style: AppTheme.inter(size: 14, weight: FontWeight.w600, color: AppTheme.cyan)),
              ),
            ],
          ],
        ),
      );

  static String _relativeDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Just now';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}
