import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../controllers/beginner_hub/beginner_hub_controller.dart';
import '../../controllers/fandoms/fandom_suggestions.dart';
import '../../models/fandom.dart';
import '../../models/glossary_term.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/glossary_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fandom_stats.dart';
import '../../widgets/follow_button.dart';
import '../../widgets/lore_card.dart';
import '../fandoms/fandom_page_screen.dart';
import '../home/fan_home_screen.dart';
import '../shop/shop_tab.dart' show showGuestLoginSheet;
import 'fandom_detail_screen.dart';
import 'glossary_screen.dart';
import 'post_list_screen.dart';

class BeginnerFanHubScreen extends StatefulWidget {
  const BeginnerFanHubScreen({super.key});

  @override
  State<BeginnerFanHubScreen> createState() => _BeginnerFanHubScreenState();
}

class _BeginnerFanHubScreenState extends State<BeginnerFanHubScreen> {
  static const int _maxFandoms = 8;
  static const int _maxStories = 6;

  final _controller = const BeginnerHubController();
  final _fandomsKey = GlobalKey();
  late final Future<Box> _flags = BeginnerHubController.openFlags();
  late Future<FandomSuggestions> _suggestions =
      FandomSuggestions.load(limit: _maxFandoms);
  late final Stream<List<Post>> _beginnerPosts = _controller.beginnerPosts();
  late final Stream<List<GlossaryTerm>> _terms =
      GlossaryService.instance.watchTerms();
  List<String> _interests = const [];
  List<Post> _latestStories = const [];

  @override
  void initState() {
    super.initState();
    AuthService.instance.userNotifier.addListener(_onUserChanged);
    _loadInterests();
  }

  @override
  void dispose() {
    AuthService.instance.userNotifier.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (!mounted) return;
    setState(() {});
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    final interests = await FandomSuggestions.interestCategories();
    if (mounted) setState(() => _interests = interests);
  }

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _openBeginnerList() => _push(PostListScreen(
        title: 'Beginner Stories',
        stream: _controller.beginnerPosts(),
        emptyMessage: 'Beginner guides are coming soon.',
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Beginner Fan Hub', style: AppTheme.orbitron(size: 13)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _intro(),
          const SizedBox(height: 16),
          _checklist(),
          const SizedBox(height: 28),
          _sectionTitle(Icons.hub_outlined, AppTheme.orange, 'FANDOMS TO START WITH',
              'Follow a few to fill your feed', key: _fandomsKey),
          const SizedBox(height: 12),
          _fandomSection(),
          const SizedBox(height: 28),
          _sectionTitle(Icons.menu_book_outlined, AppTheme.cyan, 'BEGINNER STORIES',
              'No prior knowledge needed'),
          const SizedBox(height: 12),
          _storiesSection(),
          _lingoSection(),
          const SizedBox(height: 28),
          _sectionTitle(Icons.near_me_outlined, AppTheme.pink, 'GET AROUND THE APP',
              'Where everything lives'),
          const SizedBox(height: 12),
          _getAround(),
        ],
      ),
    );
  }

  // ── Welcome ────────────────────────────────────────────────────────────────

  Widget _intro() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.accent.withValues(alpha: 0.28),
              AppTheme.cyan.withValues(alpha: 0.12),
            ],
          ),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.25),
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome to Fandom Verse',
                      style: GoogleFonts.orbitron(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Start here: follow a few fandoms, read a beginner guide, and learn the lingo.',
                    style: AppTheme.inter(size: 12, color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Your first steps ───────────────────────────────────────────────────────

  Widget _checklist() => FutureBuilder<Box>(
        future: _flags,
        builder: (context, snap) {
          final box = snap.data;
          if (box == null) return _buildChecklist(null);
          return ValueListenableBuilder<Box>(
            valueListenable: box.listenable(keys: [
              BeginnerHubController.readGuideKey,
              BeginnerHubController.openedGlossaryKey,
            ]),
            builder: (context, b, _) => _buildChecklist(b),
          );
        },
      );

  Widget _buildChecklist(Box? flags) {
    final steps = _controller.checklist(AuthService.instance.currentUser, flags);
    if (_controller.allDone(steps)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.green, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You\'re all set',
                      style: AppTheme.orbitron(size: 13, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('You know your way around. Enjoy the Fandom Verse!',
                      style: AppTheme.inter(size: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final doneCount = steps.where((s) => s.done).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('YOUR FIRST STEPS',
                    style: AppTheme.orbitron(size: 11, letterSpacing: 0.8)),
              ),
              Text('$doneCount of ${steps.length} done',
                  style: AppTheme.inter(size: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < steps.length; i++) _stepRow(i, steps[i]),
        ],
      ),
    );
  }

  Widget _stepRow(int index, HubStep step) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: step.done ? null : () => _onStepTap(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                step.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: step.done ? Colors.green : Colors.grey,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.title,
                        style: AppTheme.inter(
                          size: 13,
                          weight: FontWeight.w600,
                          color: step.done ? Colors.grey : Colors.white,
                        ).copyWith(
                            decoration: step.done ? TextDecoration.lineThrough : null)),
                    Text(step.subtitle,
                        style: AppTheme.inter(size: 11, color: Colors.grey)),
                  ],
                ),
              ),
              if (!step.done)
                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
        ),
      );

  void _onStepTap(int index) {
    switch (index) {
      case 0:
        if (AuthService.instance.currentUser == null) {
          showGuestLoginSheet(context, feature: 'Following fandoms');
        } else {
          final target = _fandomsKey.currentContext;
          if (target != null) {
            Scrollable.ensureVisible(target,
                duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
          }
        }
      case 1:
        if (_latestStories.isNotEmpty) {
          _push(FandomDetailScreen(post: _latestStories.first));
        } else {
          _openBeginnerList();
        }
      case 2:
        _push(const GlossaryScreen());
    }
  }

  Widget _sectionTitle(IconData icon, Color color, String title, String subtitle,
          {Key? key}) =>
      Row(
        key: key,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.orbitron(size: 10, letterSpacing: 0.8)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text('· $subtitle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.inter(size: 11, color: Colors.grey)),
          ),
        ],
      );

  // ── Fandoms to start with ──────────────────────────────────────────────────

  Widget _fandomSection() => FutureBuilder<FandomSuggestions>(
        future: _suggestions,
        builder: (context, snap) {
          if (snap.hasError) {
            debugPrint('Hub fandoms load error: ${snap.error}');
            return _stateBox(Icons.wifi_off, 'Could not load fandoms',
                'Check your connection and try again.',
                onRetry: () => setState(() =>
                    _suggestions = FandomSuggestions.load(limit: _maxFandoms)));
          }
          if (snap.connectionState != ConnectionState.done) {
            return _loading(AppTheme.orange);
          }
          final fandoms = snap.data?.fandoms ?? const <Fandom>[];
          if (fandoms.isEmpty) {
            return _stateBox(Icons.hub_outlined, 'No fandoms to explore yet',
                'New fandom worlds will appear here soon.');
          }
          return SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: fandoms.length,
              separatorBuilder: (context, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _fandomCard(fandoms[i]),
            ),
          );
        },
      );

  Widget _fandomCard(Fandom f) => GestureDetector(
        onTap: () => _push(FandomPageScreen(fandomId: f.id, initial: f)),
        child: Container(
          width: 200,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 96,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    f.coverImageUrl.isEmpty
                        ? _coverFallback()
                        : Image.network(f.coverImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, e, st) => _coverFallback()),
                    Positioned(left: 10, bottom: 8, child: FandomLogo(fandom: f, size: 38)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.orbitron(size: 11, weight: FontWeight.w700)),
                      if (f.categoryName.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.cyan,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(f.categoryName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(f.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(followersLabel(f.followerCount),
                          style: AppTheme.inter(size: 10, color: AppTheme.cyan)),
                      const Spacer(),
                      FollowButton(fandomId: f.id, compact: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _coverFallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accent.withValues(alpha: 0.45),
              AppTheme.cyan.withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  // ── Beginner stories ───────────────────────────────────────────────────────

  Widget _storiesSection() => StreamBuilder<List<Post>>(
        stream: _beginnerPosts,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Hub beginner stories load error: ${snapshot.error}');
            return _stateBox(Icons.wifi_off, 'Could not load beginner stories',
                'Check your connection and try again.');
          }
          if (!snapshot.hasData) return _loading(AppTheme.cyan);
          final ranked = _controller.rankBeginnerPosts(
            snapshot.data!,
            followedFandomIds:
                AuthService.instance.currentUser?.followedFandomIds ?? const [],
            interestCategories: _interests,
          );
          _latestStories = ranked;
          if (ranked.isEmpty) {
            return _stateBox(Icons.auto_stories_outlined,
                'Beginner guides are coming soon.',
                'Starter guides will show up here as they\'re published.');
          }
          return Column(
            children: [
              for (final p in ranked.take(_maxStories))
                LoreCard(key: ValueKey(p.id), post: p),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _openBeginnerList,
                  icon: const Icon(Icons.arrow_forward_rounded,
                      color: AppTheme.cyan, size: 16),
                  label: Text('See all',
                      style: AppTheme.inter(
                          size: 13, color: AppTheme.cyan, weight: FontWeight.w600)),
                ),
              ),
            ],
          );
        },
      );

  // ── Learn the lingo ────────────────────────────────────────────────────────

  Widget _lingoSection() => StreamBuilder<List<GlossaryTerm>>(
        stream: _terms,
        builder: (context, snapshot) {
          final Widget body;
          if (snapshot.hasError) {
            debugPrint('Hub glossary load error: ${snapshot.error}');
            body = _stateBox(Icons.wifi_off, 'Could not load the glossary',
                'Check your connection and try again.');
          } else if (!snapshot.hasData) {
            body = _loading(AppTheme.accent);
          } else {
            final terms = snapshot.data!;
            final today = _controller.termOfTheDay(terms, DateTime.now());
            if (today == null) return const SizedBox.shrink();
            body = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _termOfTheDay(today),
                const SizedBox(height: 10),
                for (final t in _controller.moreTerms(terms, today)) _termRow(t),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _push(const GlossaryScreen()),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.accent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.menu_book_rounded, color: AppTheme.accent, size: 18),
                    label: Text('Open full Glossary',
                        style: AppTheme.inter(
                            size: 13, color: AppTheme.accent, weight: FontWeight.w700)),
                  ),
                ),
              ],
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(Icons.translate_rounded, AppTheme.accent, 'LEARN THE LINGO',
                    'Decode fan speak'),
                const SizedBox(height: 12),
                body,
              ],
            ),
          );
        },
      );

  Widget _termOfTheDay(GlossaryTerm t) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.card,
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.6), width: 1.3),
          boxShadow: [
            BoxShadow(color: AppTheme.accent.withValues(alpha: 0.2), blurRadius: 16),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TERM OF THE DAY',
                style: AppTheme.orbitron(size: 9, color: AppTheme.accent, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(t.term, style: AppTheme.orbitron(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(t.definition,
                style: AppTheme.inter(size: 13, color: Colors.white70, height: 1.5)),
          ],
        ),
      );

  Widget _termRow(GlossaryTerm t) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.term,
                style: AppTheme.inter(size: 13, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(t.definition,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.inter(size: 12, color: Colors.grey)),
          ],
        ),
      );

  // ── Get around the app ─────────────────────────────────────────────────────

  Widget _getAround() {
    WidgetBuilder backToHub() => (_) => const BeginnerFanHubScreen();
    final tiles = [
      (Icons.explore_outlined, AppTheme.orange, 'Explore fandoms',
          'Browse lore, deep dives and the glossary',
          () => FanHomeScreen.openTab(context, FanHomeScreen.loreTab, backTo: backToHub())),
      (Icons.event_outlined, AppTheme.pink, 'Events near you',
          'Conventions and meetups on a map',
          () => FanHomeScreen.openTab(context, FanHomeScreen.eventsTab, backTo: backToHub())),
      (Icons.storefront_outlined, AppTheme.cyan, 'Shop merch',
          'Official gear from your fandoms',
          () => FanHomeScreen.openTab(context, FanHomeScreen.shopTab, backTo: backToHub())),
      (Icons.smart_toy_outlined, AppTheme.accent, 'Ask the Fan Helper',
          'Questions about the app? Just ask',
          () => showFanAssistant(context)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        for (final (icon, color, title, line, onTap) in tiles)
          Material(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 24),
                    const Spacer(),
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 13, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(line,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 11, color: Colors.grey, height: 1.3)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Shared state widgets ──────────────────────────────────────────────────

  Widget _loading(Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: color)),
      );

  Widget _stateBox(IconData icon, String title, String subtitle,
          {VoidCallback? onRetry}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey, size: 30),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTheme.orbitron(size: 11, color: Colors.grey, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.inter(size: 11, color: Colors.grey)),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text('Try again',
                    style: AppTheme.inter(size: 12, color: AppTheme.cyan)),
              ),
          ],
        ),
      );
}
