import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_category.dart';
import '../../models/post.dart';
import '../../services/category_service.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icons.dart';
import '../../utils/youtube_utils.dart';
import '../../widgets/trending_badge.dart';
import 'fandom_detail_screen.dart';

const String _kArtwork = 'assets/images/onboarding/onboarding_bg.jpg';

/// Active posts tagged Deep Dive (contentDepth == 'deep'), newest first.
Stream<List<Post>> deepDivePosts() => PostService.instance
    .watchActivePosts()
    .map((posts) => posts.where((p) => p.contentDepth == 'deep').toList());

IconData _kindIcon(String kind) {
  switch (kind) {
    case 'trivia':
      return Icons.lightbulb_outline_rounded;
    case 'lore':
      return Icons.auto_stories_rounded;
    case 'interview':
      return Icons.mic_none_rounded;
    default:
      return Icons.travel_explore_rounded;
  }
}

Color _kindColor(String kind) {
  switch (kind) {
    case 'trivia':
      return AppTheme.orange;
    case 'interview':
      return AppTheme.pink;
    case 'lore':
      return AppTheme.cyan;
    default:
      return AppTheme.accent;
  }
}

String _kindLabel(String kind) => kDeepDiveTypeLabels[kind] ?? 'Deep Dive';

/// Expert-fan hub: hidden trivia, advanced lore and behind-the-scenes
/// interviews. Built on existing Posts (Deep Dive depth + deepDiveType).
class DeepDiveScreen extends StatefulWidget {
  /// Test-only data overrides (default to Firestore).
  @visibleForTesting
  final Stream<List<Post>>? postsStream;
  @visibleForTesting
  final Stream<List<AppCategory>>? categoriesStream;

  const DeepDiveScreen({super.key, this.postsStream, this.categoriesStream});

  @override
  State<DeepDiveScreen> createState() => _DeepDiveScreenState();
}

class _DeepDiveScreenState extends State<DeepDiveScreen> {
  late final Stream<List<Post>> _posts = widget.postsStream ?? deepDivePosts();
  late final Stream<List<AppCategory>> _categories =
      widget.categoriesStream ?? CategoryService.instance.watchCategories();

  String? _kind; // null = all
  String? _fandom; // null = all

  void _open(Post p) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FandomDetailScreen(post: p)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: StreamBuilder<List<AppCategory>>(
        stream: _categories,
        builder: (context, catSnap) {
          final catsByKey = {for (final c in catSnap.data ?? <AppCategory>[]) c.key: c};
          return StreamBuilder<List<Post>>(
            stream: _posts,
            builder: (context, snapshot) => CustomScrollView(
              slivers: [
                _header(snapshot.data?.length),
                SliverToBoxAdapter(child: _kindTabs(snapshot.data ?? const [])),
                if (snapshot.hasData && snapshot.data!.isNotEmpty)
                  SliverToBoxAdapter(child: _fandomFilters(snapshot.data!, catsByKey)),
                ..._results(snapshot, catsByKey),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header(int? count) => SliverAppBar(
        pinned: true,
        expandedHeight: 210,
        backgroundColor: AppTheme.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Deep Dive', style: AppTheme.orbitron(size: 13)),
        flexibleSpace: FlexibleSpaceBar(
          collapseMode: CollapseMode.parallax,
          background: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(_kArtwork,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.6, 0.2),
                  errorBuilder: (ctx, e, st) => const SizedBox.shrink()),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF05030F).withValues(alpha: 0.6),
                      const Color(0xFF0A0620).withValues(alpha: 0.7),
                      AppTheme.bg,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.water_rounded, color: AppTheme.cyan, size: 16),
                        const SizedBox(width: 6),
                        Text('FOR EXPERT FANS',
                            style: AppTheme.orbitron(size: 9, color: AppTheme.cyan, letterSpacing: 2)),
                        if (count != null) ...[
                          const SizedBox(width: 10),
                          Text('· $count ${count == 1 ? 'dive' : 'dives'}',
                              style: AppTheme.inter(size: 11, color: Colors.white54)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [Color(0xFFC084FC), AppTheme.accent, AppTheme.cyan],
                      ).createShader(r),
                      child: Text('DEEP DIVE',
                          style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hidden trivia, advanced lore and behind-the-scenes interviews '
                      'for fans who already know the basics.',
                      style: AppTheme.inter(size: 12, color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  // ── Filters ──────────────────────────────────────────────────────────────

  Widget _kindTabs(List<Post> posts) {
    Widget tab(String? kind, String label, IconData icon, Color color) {
      final selected = _kind == kind;
      final count = kind == null ? posts.length : posts.where((p) => p.deepDiveType == kind).length;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _kind = kind),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: selected
                  ? LinearGradient(colors: [color.withValues(alpha: 0.45), AppTheme.accent.withValues(alpha: 0.25)])
                  : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: selected ? color : Colors.white.withValues(alpha: 0.12)),
              boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12)] : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: selected ? Colors.white : color),
                const SizedBox(height: 4),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(
                        size: 11,
                        color: selected ? Colors.white : Colors.white70,
                        weight: selected ? FontWeight.w700 : FontWeight.w500)),
                Text('$count', style: AppTheme.inter(size: 9, color: Colors.white38)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 0),
      child: Row(
        children: [
          tab(null, 'All', Icons.water_rounded, AppTheme.accent),
          for (final k in kDeepDiveTypes)
            tab(k, k == 'lore' ? 'Lore' : (k == 'trivia' ? 'Trivia' : 'Interviews'),
                _kindIcon(k), _kindColor(k)),
        ],
      ),
    );
  }

  Widget _fandomFilters(List<Post> posts, Map<String, AppCategory> catsByKey) {
    final keys = posts.map((p) => p.category).where((k) => k.isNotEmpty).toSet().toList()
      ..sort((a, b) => (catsByKey[a]?.name ?? a).compareTo(catsByKey[b]?.name ?? b));
    if (keys.isEmpty) return const SizedBox(height: 8);
    Widget chip(String? key, String label, IconData icon) {
      final selected = _fandom == key;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          avatar: Icon(icon, size: 14, color: selected ? Colors.white : AppTheme.cyan),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => setState(() => _fandom = key),
          labelStyle: AppTheme.inter(
              size: 12, color: selected ? Colors.white : Colors.white70,
              weight: selected ? FontWeight.w700 : FontWeight.w500),
          selectedColor: AppTheme.accent.withValues(alpha: 0.45),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          side: BorderSide(color: selected ? AppTheme.accent : Colors.white.withValues(alpha: 0.12)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }

    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        children: [
          chip(null, 'All fandoms', Icons.public_rounded),
          for (final k in keys)
            chip(k, catsByKey[k]?.name ?? k,
                catsByKey[k] != null ? categoryIcon(catsByKey[k]!) : Icons.auto_awesome_rounded),
        ],
      ),
    );
  }

  // ── Results ──────────────────────────────────────────────────────────────

  List<Widget> _results(AsyncSnapshot<List<Post>> snapshot, Map<String, AppCategory> catsByKey) {
    if (snapshot.hasError) {
      return [_state(Icons.wifi_off_rounded, 'Could not load Deep Dive', 'Check your connection and try again.')];
    }
    if (!snapshot.hasData) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan)),
        ),
      ];
    }
    final all = snapshot.data!;
    if (all.isEmpty) {
      return [
        _state(Icons.water_rounded, 'No deep dives yet',
            'Expert trivia, lore and interviews will surface here soon.'),
      ];
    }
    final filtered = all
        .where((p) => (_kind == null || p.deepDiveType == _kind) && (_fandom == null || p.category == _fandom))
        .toList();
    if (filtered.isEmpty) {
      return [
        _state(
          _kindIcon(_kind ?? ''),
          'Nothing here yet',
          'No ${_kind == null ? 'deep dives' : _kindLabel(_kind!).toLowerCase()} for this fandom so far.',
          action: TextButton(
            onPressed: () => setState(() {
              _kind = null;
              _fandom = null;
            }),
            child: Text('SHOW ALL DEEP DIVES', style: AppTheme.orbitron(size: 9, color: AppTheme.cyan)),
          ),
        ),
      ];
    }
    final featured = filtered.first;
    final rest = filtered.skip(1).toList();
    String? catName(Post p) => p.category.isEmpty ? null : (catsByKey[p.category]?.name ?? p.category);
    final filterKey = '$_kind|$_fandom';
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        sliver: SliverToBoxAdapter(
          child: _FadeIn(
            key: ValueKey('f-${featured.id}-$filterKey'),
            delayMs: 0,
            child: _DeepDiveCard(post: featured, categoryName: catName(featured), featured: true, onTap: () => _open(featured)),
          ),
        ),
      ),
      if (rest.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              mainAxisExtent: 250,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _FadeIn(
                key: ValueKey('${rest[i].id}-$filterKey'),
                delayMs: ((i + 1) * 50).clamp(0, 400),
                child: _DeepDiveCard(post: rest[i], categoryName: catName(rest[i]), onTap: () => _open(rest[i])),
              ),
              childCount: rest.length,
            ),
          ),
        ),
    ];
  }

  Widget _state(IconData icon, String title, String subtitle, {Widget? action}) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white38, size: 38),
                const SizedBox(height: 10),
                Text(title,
                    textAlign: TextAlign.center,
                    style: AppTheme.orbitron(size: 12, color: Colors.white60, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: AppTheme.inter(size: 11, color: Colors.white38)),
                if (action != null) ...[const SizedBox(height: 8), action],
              ],
            ),
          ),
        ),
      );
}

// ── Cards ─────────────────────────────────────────────────────────────────────

class _DeepDiveCard extends StatelessWidget {
  final Post post;
  final String? categoryName;
  final bool featured;
  final VoidCallback onTap;

  const _DeepDiveCard({
    required this.post,
    required this.categoryName,
    required this.onTap,
    this.featured = false,
  });

  String? get _imageUrl {
    if (post.imageUrl.isNotEmpty) return post.imageUrl;
    if (post.hasVideo) {
      final id = extractYoutubeVideoId(post.youtubeUrl!);
      if (id != null) return youtubeThumbnailUrl(id);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final color = _kindColor(post.deepDiveType);
    final image = _imageUrl;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          height: featured ? 260 : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppTheme.card,
            border: Border.all(color: color.withValues(alpha: featured ? 0.7 : 0.35)),
            boxShadow: featured
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 22)]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: featured ? _featuredBody(image, color) : _gridBody(image, color),
          ),
        ),
      ),
    );
  }

  Widget _media(String? image, Color color) => Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Image.network(image,
                fit: BoxFit.cover,
                errorBuilder: (ctx, e, st) => _placeholder(color))
          else
            _placeholder(color),
          if (post.hasVideo)
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
              ),
            ),
        ],
      );

  Widget _placeholder(Color color) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.35), AppTheme.bg],
          ),
        ),
        child: Center(child: Icon(_kindIcon(post.deepDiveType), color: Colors.white38, size: 40)),
      );

  Widget _badges(Color color) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _pill(_kindLabel(post.deepDiveType), _kindIcon(post.deepDiveType), color),
          if (categoryName != null) _pill(categoryName!, Icons.public_rounded, Colors.white70),
        ],
      );

  Widget _pill(String label, IconData icon, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(size: 10, color: Colors.white, weight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _featuredBody(String? image, Color color) => Stack(
        fit: StackFit.expand,
        children: [
          _media(image, color),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppTheme.bg.withValues(alpha: 0.97), AppTheme.bg.withValues(alpha: 0.4), Colors.transparent],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.cyan]),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text('FEATURED DIVE',
                      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          Positioned(top: 12, right: 12, child: TrendingBadge(postId: post.id)),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _badges(color),
                const SizedBox(height: 8),
                Text(post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.orbitron(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(size: 12, color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
        ],
      );

  Widget _gridBody(String? image, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 118,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _media(image, color),
                Positioned(left: 10, bottom: 10, right: 10, child: _badges(color)),
                Positioned(top: 8, right: 8, child: TrendingBadge(postId: post.id)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 14, color: Colors.white, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(post.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 12, color: Colors.white60, height: 1.4)),
                  ),
                  Row(
                    children: [
                      Text('Dive in', style: AppTheme.inter(size: 11, color: color, weight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: color, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _FadeIn extends StatelessWidget {
  final int delayMs;
  final Widget child;
  const _FadeIn({super.key, required this.delayMs, required this.child});

  @override
  Widget build(BuildContext context) {
    final total = 340 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
      ),
    );
  }
}

/// Lore-tab entry section: cinematic banner with live counts per kind.
class DeepDiveTeaser extends StatefulWidget {
  const DeepDiveTeaser({super.key});

  @override
  State<DeepDiveTeaser> createState() => _DeepDiveTeaserState();
}

class _DeepDiveTeaserState extends State<DeepDiveTeaser> {
  late final Stream<List<Post>> _posts = deepDivePosts();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: _posts,
      builder: (context, snapshot) {
        final posts = snapshot.data ?? const <Post>[];
        int count(String k) => posts.where((p) => p.deepDiveType == k).length;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeepDiveScreen()),
            ),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.45)),
                boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.25), blurRadius: 20)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(_kArtwork,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0.6, 0.3),
                          errorBuilder: (ctx, e, st) => const SizedBox.shrink()),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              const Color(0xFF070418).withValues(alpha: 0.96),
                              const Color(0xFF0A0620).withValues(alpha: 0.75),
                              const Color(0xFF0A0620).withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ShaderMask(
                                shaderCallback: (r) => const LinearGradient(
                                  colors: [Color(0xFFC084FC), AppTheme.cyan],
                                ).createShader(r),
                                child: Text('DEEP DIVE',
                                    style: GoogleFonts.orbitron(
                                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_rounded, color: AppTheme.cyan, size: 20),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Already a fan? Go beyond the basics.',
                              style: AppTheme.inter(size: 12, color: Colors.white70)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final k in kDeepDiveTypes)
                                _teaserPill(_kindLabel(k), _kindIcon(k), _kindColor(k),
                                    snapshot.hasData ? count(k) : null),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _teaserPill(String label, IconData icon, Color color, int? count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(count == null ? label : '$label · $count',
                style: AppTheme.inter(size: 11, color: Colors.white, weight: FontWeight.w600)),
          ],
        ),
      );
}
