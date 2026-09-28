import 'dart:async';

import 'package:flutter/material.dart';
import '../../controllers/fandoms/fandom_page_controller.dart';
import '../../models/fandom.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/fandom_service.dart';
import '../../services/post_service.dart';
import '../../utils/fandom_stats.dart';
import '../../services/merchandise_service.dart';
import '../../services/event_service.dart';
import '../../models/merchandise.dart';
import '../../models/event_item.dart';
import '../shop/shop_tab.dart' show MerchProductCard, kMerchGridDelegate;
import '../events/widgets/event_card.dart';
import '../../theme/app_theme.dart';
import '../../widgets/follow_button.dart';
import '../../widgets/lore_card.dart';

class FandomPageScreen extends StatefulWidget {
  final String fandomId;
  final Fandom? initial;
  const FandomPageScreen({super.key, required this.fandomId, this.initial});

  @override
  State<FandomPageScreen> createState() => _FandomPageScreenState();
}

class _FandomPageScreenState extends State<FandomPageScreen> {
  final _controller = const FandomPageController();
  Fandom? _fandom;
  bool _fandomLoaded = false;
  Object? _fandomError;
  StreamSubscription<Fandom?>? _fandomSub;
  StreamSubscription<List<Post>>? _postSub;
  List<Post>? _posts;
  Object? _postsError;
  StreamSubscription<List<Merchandise>>? _merchSub;
  List<Merchandise> _merch = const [];
  Object? _merchError;
  StreamSubscription<List<EventItem>>? _eventSub;
  List<EventItem> _events = const [];
  Object? _eventsError;
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    _fandom = widget.initial;
    if (AuthService.instance.isLoggedIn) {
      FandomService.instance.recordView(widget.fandomId).catchError(
          (Object e) => debugPrint('Fandom view count failed: $e'));
    }
    _loadFandom();
    _listenPosts();
    _listenMerch();
    _listenEvents();
  }

  @override
  void dispose() {
    _fandomSub?.cancel();
    _postSub?.cancel();
    _merchSub?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }

  void _listenMerch() {
    _merchSub?.cancel();
    setState(() => _merchError = null);
    _merchSub = MerchandiseService.instance
        .watchMerchandiseByFandom(widget.fandomId)
        .listen(
          (items) => setState(() {
            _merch = items;
            _merchError = null;
          }),
          onError: (Object e) {
            debugPrint('Fandom merch load error: $e');
            setState(() => _merchError = e);
          },
        );
  }

  void _listenEvents() {
    _eventSub?.cancel();
    setState(() => _eventsError = null);
    _eventSub = EventService.instance
        .watchEventsByFandom(widget.fandomId)
        .listen(
          (events) => setState(() {
            _events = events;
            _eventsError = null;
          }),
          onError: (Object e) {
            debugPrint('Fandom events load error: $e');
            setState(() => _eventsError = e);
          },
        );
  }

  void _loadFandom() {
    _fandomSub?.cancel();
    setState(() => _fandomError = null);
    _fandomSub = FandomService.instance.watchById(widget.fandomId).listen(
          (f) => setState(() {
            _fandom = f;
            _fandomLoaded = true;
            _fandomError = null;
          }),
          onError: (Object e) {
            debugPrint('Fandom load error: $e');
            setState(() => _fandomError = e);
          },
        );
  }

  void _listenPosts() {
    _postSub?.cancel();
    setState(() {
      _posts = null;
      _postsError = null;
    });
    _postSub = PostService.instance
        .watchPostsByFandom(widget.fandomId)
        .listen(
          (posts) => setState(() {
            _posts = posts;
            _postsError = null;
          }),
          onError: (Object e) {
            debugPrint('Fandom posts load error: $e');
            setState(() => _postsError = e);
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final fandom = _fandom;
    if (_fandomError != null && fandom == null) {
      return _plainScaffold(_stateBox(Icons.wifi_off, 'Could not load this fandom',
          'Check your connection and try again.',
          onRetry: _loadFandom));
    }
    if (!_fandomLoaded && fandom == null) {
      return _plainScaffold(const Center(
          child: CircularProgressIndicator(color: AppTheme.cyan)));
    }
    if (fandom == null || (_fandomLoaded && !fandom.isActive)) {
      return _plainScaffold(_stateBox(
        Icons.hub_outlined,
        'This fandom isn\'t available',
        'It may have been removed or renamed. Go back to keep exploring.',
      ));
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: AppTheme.card,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(background: _cover(fandom)),
          ),
          SliverToBoxAdapter(child: _info(fandom)),
          ..._postSlivers(fandom),
        ],
      ),
    );
  }

  Widget _plainScaffold(Widget body) => Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          backgroundColor: AppTheme.card,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.initial?.name ?? 'Fandom',
              style: AppTheme.orbitron(size: 13)),
        ),
        body: body,
      );

  Widget _cover(Fandom f) {
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.5),
            AppTheme.cyan.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
    if (f.coverImageUrl.isEmpty) return fallback;
    return Image.network(f.coverImageUrl,
        fit: BoxFit.cover, errorBuilder: (ctx, e, st) => fallback);
  }

  Widget _info(Fandom f) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FandomLogo(fandom: f, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.orbitron(
                              size: 18, weight: FontWeight.w700)),
                      if (f.categoryName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.cyan,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(f.categoryName.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.people_alt_outlined,
                    color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    followersLabel(f.followerCount),
                    style: AppTheme.inter(size: 12, color: Colors.grey),
                  ),
                ),
                FollowButton(fandomId: f.id),
              ],
            ),
            if (f.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(f.description,
                  style: AppTheme.inter(
                      size: 13, color: Colors.white70, height: 1.5)),
            ],
            if (f.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final t in f.tags) FandomTagChip(tag: t)],
              ),
            ],
          ],
        ),
      );

  List<Widget> _postSlivers(Fandom f) {
    final raw = _posts;
    if (raw == null && _postsError == null) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.cyan)),
          ),
        ),
      ];
    }
    final posts = raw == null ? const <Post>[] : _controller.visiblePosts(raw);
    final postTabs = posts.isEmpty
        ? [FandomTab('all', 'All', posts)]
        : _controller.tabsFor(posts);
    final tabs = <({String key, String label})>[
      for (final t in postTabs) (key: t.key, label: '${t.label} (${t.posts.length})'),
      if (_merch.isNotEmpty || _merchError != null)
        (key: 'merch', label: _merchError != null ? 'Merch' : 'Merch (${_merch.length})'),
      if (_events.isNotEmpty || _eventsError != null)
        (key: 'events', label: _eventsError != null ? 'Events' : 'Events (${_events.length})'),
    ];

    Widget postsState() => _postsError != null
        ? _stateBox(Icons.wifi_off, 'Could not load posts',
            'Check your connection and try again.',
            onRetry: _listenPosts)
        : _stateBox(Icons.menu_book_outlined, 'No posts for ${f.name} yet',
            'New lore will appear here soon.');

    if (tabs.length == 1 && posts.isEmpty) {
      return [SliverToBoxAdapter(child: postsState())];
    }

    var index = tabs.indexWhere((t) => t.key == _selectedTab);
    if (index < 0) index = 0;
    final selectedKey = tabs[index].key;

    final Widget content;
    if (selectedKey == 'merch') {
      content = _merchError != null
          ? SliverToBoxAdapter(
              child: _stateBox(Icons.wifi_off, 'Could not load merch',
                  'Check your connection and try again.',
                  onRetry: _listenMerch))
          : SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              sliver: SliverGrid.builder(
                gridDelegate: kMerchGridDelegate,
                itemCount: _merch.length,
                itemBuilder: (context, i) => MerchProductCard(
                    key: ValueKey(_merch[i].id), item: _merch[i]),
              ),
            );
    } else if (selectedKey == 'events') {
      content = _eventsError != null
          ? SliverToBoxAdapter(
              child: _stateBox(Icons.wifi_off, 'Could not load events',
                  'Check your connection and try again.',
                  onRetry: _listenEvents))
          : SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              sliver: SliverList.builder(
                itemCount: _events.length,
                itemBuilder: (context, i) =>
                    EventCard(key: ValueKey(_events[i].id), event: _events[i]),
              ),
            );
    } else {
      final selected = postTabs.firstWhere((t) => t.key == selectedKey,
          orElse: () => postTabs.first);
      content = selected.posts.isEmpty
          ? SliverToBoxAdapter(child: postsState())
          : SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              sliver: SliverList.builder(
                itemCount: selected.posts.length,
                itemBuilder: (context, i) => LoreCard(
                    key: ValueKey(selected.posts[i].id),
                    post: selected.posts[i]),
              ),
            );
    }

    return [
      SliverToBoxAdapter(
        child: DefaultTabController(
          key: ValueKey(tabs.map((t) => t.key).join('|')),
          length: tabs.length,
          initialIndex: index,
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            indicatorColor: AppTheme.cyan,
            labelColor: AppTheme.cyan,
            unselectedLabelColor: Colors.grey,
            dividerColor: AppTheme.border,
            labelStyle: AppTheme.orbitron(size: 10, weight: FontWeight.w700),
            unselectedLabelStyle:
                AppTheme.orbitron(size: 10, weight: FontWeight.w500),
            onTap: (i) => setState(() => _selectedTab = tabs[i].key),
            tabs: [for (final t in tabs) Tab(text: t.label)],
          ),
        ),
      ),
      content,
    ];
  }

  Widget _stateBox(IconData icon, String title, String subtitle,
          {VoidCallback? onRetry}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey, size: 36),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(
                      size: 13, color: Colors.white70, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(size: 12, color: Colors.grey)),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRetry,
                  child: Text('Try again',
                      style: AppTheme.inter(size: 12, color: AppTheme.cyan)),
                ),
              ],
            ],
          ),
        ),
      );
}

class FandomLogo extends StatelessWidget {
  final Fandom fandom;
  final double size;
  const FandomLogo({super.key, required this.fandom, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        fandom.name.isEmpty ? '?' : fandom.name.characters.first.toUpperCase(),
        style: AppTheme.orbitron(size: size * 0.38, color: AppTheme.cyan),
      ),
    );
    if (fandom.logoUrl.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: Image.network(fandom.logoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, e, st) => fallback),
    );
  }
}

class FandomTagChip extends StatelessWidget {
  final String tag;
  const FandomTagChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
        ),
        child: Text('#$tag',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.inter(size: 10, color: Colors.white70)),
      );
}

class FandomLinkChip extends StatelessWidget {
  final String fandomId;
  final String label;
  const FandomLinkChip({super.key, required this.fandomId, required this.label});

  @override
  Widget build(BuildContext context) => Material(
        color: AppTheme.accent.withValues(alpha: 0.15),
        shape: StadiumBorder(
            side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => FandomPageScreen(fandomId: fandomId)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hub_outlined, color: Colors.white70, size: 13),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label.isEmpty ? 'View fandom' : label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(
                        size: 11, color: Colors.white, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.chevron_right, color: Colors.white70, size: 14),
              ],
            ),
          ),
        ),
      );
}
