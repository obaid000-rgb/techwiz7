import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_category.dart';
import '../../models/post.dart';
import '../../services/category_service.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icons.dart';
import '../../widgets/lore_card.dart';
import 'category_detail_screen.dart';
import 'glossary_screen.dart';
import 'post_list_screen.dart';

/// Starting point for new fans, assembled from existing data: active
/// categories, beginner-depth posts, and the glossary. Reached from the
/// "New here?" card at the top of the Lore tab.
class BeginnerFanHubScreen extends StatefulWidget {
  const BeginnerFanHubScreen({super.key});

  @override
  State<BeginnerFanHubScreen> createState() => _BeginnerFanHubScreenState();
}

class _BeginnerFanHubScreenState extends State<BeginnerFanHubScreen> {
  static const int _maxCategories = 8;
  static const int _maxReads = 5;

  late final Stream<List<AppCategory>> _categories =
      CategoryService.instance.watchActiveCategories();
  // Same beginner-depth filter Home uses, over active posts only.
  static Stream<List<Post>> _beginnerStream() => PostService.instance
      .watchActivePosts()
      .map((posts) => posts.where((p) => p.contentDepth == 'beginner').toList());

  late final Stream<List<Post>> _beginnerPosts = _beginnerStream();

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
          const SizedBox(height: 28),
          _sectionTitle(Icons.explore_outlined, AppTheme.orange, 'EXPLORE A FANDOM',
              'Tap a world to see its lore'),
          const SizedBox(height: 12),
          _categorySection(),
          const SizedBox(height: 28),
          _sectionTitle(Icons.menu_book_outlined, AppTheme.cyan, 'BEGINNER-FRIENDLY READS',
              'No prior knowledge needed'),
          const SizedBox(height: 12),
          _readsSection(),
          const SizedBox(height: 28),
          _sectionTitle(Icons.translate_rounded, AppTheme.accent, 'FANDOM GLOSSARY',
              'Decode the lingo'),
          const SizedBox(height: 12),
          _glossaryCard(),
        ],
      ),
    );
  }

  // ── Intro ──────────────────────────────────────────────────────────────────

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
                  Text('Welcome, new fan!',
                      style: GoogleFonts.orbitron(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Everything here is picked for newcomers: pick a world to explore, '
                    'read a few easy intros, and keep the glossary handy for any terms '
                    'you don\'t know yet.',
                    style: AppTheme.inter(size: 12, color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(IconData icon, Color color, String title, String subtitle) => Row(
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

  // ── Explore a Fandom ──────────────────────────────────────────────────────

  Widget _categorySection() => StreamBuilder<List<AppCategory>>(
        stream: _categories,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _stateBox(Icons.wifi_off, 'Could not load fandoms',
                'Check your connection and try again.');
          }
          if (!snapshot.hasData) return _loading(AppTheme.orange);
          // Featured (carousel) categories first, then the rest, by order.
          final cats = List<AppCategory>.from(snapshot.data!)
            ..sort((a, b) {
              if (a.isFeaturedInCarousel != b.isFeaturedInCarousel) {
                return a.isFeaturedInCarousel ? -1 : 1;
              }
              return a.order.compareTo(b.order);
            });
          if (cats.isEmpty) {
            return _stateBox(Icons.category_outlined, 'No fandoms to explore yet',
                'New fandom worlds will appear here soon.');
          }
          final shown = cats.take(_maxCategories).toList();
          return SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shown.length,
              separatorBuilder: (context, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _categoryCard(shown[i]),
            ),
          );
        },
      );

  Widget _categoryCard(AppCategory cat) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
        ),
        child: Container(
          width: 130,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty)
                Image.network(
                  cat.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, st) => _categoryFallback(cat),
                )
              else
                _categoryFallback(cat),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppTheme.bg.withValues(alpha: 0.95), Colors.transparent],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(
                            size: 13, color: Colors.white, weight: FontWeight.w700)),
                    if (cat.description.isNotEmpty)
                      Text(cat.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 10, color: Colors.white60)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _categoryFallback(AppCategory cat) => Container(
        color: AppTheme.orange.withValues(alpha: 0.12),
        alignment: const Alignment(0, -0.3),
        child: Icon(categoryIcon(cat), color: AppTheme.orange, size: 34),
      );

  // ── Beginner-friendly reads ───────────────────────────────────────────────

  Widget _readsSection() => StreamBuilder<List<Post>>(
        stream: _beginnerPosts,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _stateBox(Icons.wifi_off, 'Could not load beginner reads',
                'Check your connection and try again.');
          }
          if (!snapshot.hasData) return _loading(AppTheme.cyan);
          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return _stateBox(Icons.auto_stories_outlined, 'No beginner reads yet',
                'Starter guides will show up here as they\'re published.');
          }
          return Column(
            children: [
              for (final p in posts.take(_maxReads)) LoreCard(post: p),
              if (posts.length > _maxReads)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostListScreen(
                          title: 'Beginner-Friendly Reads',
                          stream: _beginnerStream(),
                          emptyMessage: 'No beginner reads yet.',
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.cyan),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('SEE ALL ${posts.length} BEGINNER READS',
                        style: AppTheme.orbitron(size: 10, color: AppTheme.cyan)),
                  ),
                ),
            ],
          );
        },
      );

  // ── Glossary ──────────────────────────────────────────────────────────────

  Widget _glossaryCard() => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GlossaryScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppTheme.card,
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.6), width: 1.3),
              boxShadow: [
                BoxShadow(color: AppTheme.accent.withValues(alpha: 0.22), blurRadius: 18),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [AppTheme.accent, AppTheme.cyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Open the Fandom Glossary',
                          style: AppTheme.inter(
                              size: 14, color: Colors.white, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Canon, OTP, headcanon, retcon… every term explained in plain words.',
                          style: AppTheme.inter(size: 11, color: Colors.white60, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: AppTheme.accent, size: 22),
              ],
            ),
          ),
        ),
      );

  // ── Shared state widgets ──────────────────────────────────────────────────

  Widget _loading(Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: color)),
      );

  Widget _stateBox(IconData icon, String title, String subtitle) => Container(
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
          ],
        ),
      );
}
