import 'package:flutter/material.dart';
import '../../controllers/fandoms/fandom_page_controller.dart';
import '../../models/app_category.dart';
import '../../models/fandom.dart';
import '../../models/post.dart';
import '../../services/fandom_service.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fandom_stats.dart';
import '../../widgets/follow_button.dart';
import '../../widgets/lore_card.dart';
import '../fandoms/fandom_page_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final AppCategory category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final _controller = const FandomPageController();
  final _searchCtr = TextEditingController();
  late Stream<List<Post>> _posts = PostService.instance.watchActivePosts();
  late Future<List<Fandom>> _fandoms = _loadFandoms();
  String _query = '';

  AppCategory get category => widget.category;

  Future<List<Fandom>> _loadFandoms() =>
      FandomService.instance.getByCategory(category.key);

  @override
  void initState() {
    super.initState();
    _searchCtr.addListener(() => setState(() => _query = _searchCtr.text));
  }

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(category.name, style: AppTheme.orbitron(size: 13)),
      ),
      body: StreamBuilder<List<Post>>(
        stream: _posts,
        builder: (context, snapshot) {
          final posts = (snapshot.data ?? [])
              .where((p) => p.category == category.key)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(),
              const SizedBox(height: 24),
              _sectionTitle('Fandoms in ${category.name}'),
              const SizedBox(height: 10),
              _fandomSection(),
              const SizedBox(height: 24),
              _sectionTitle('Latest in ${category.name}'),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.cyan),
                  ),
                )
              else if (snapshot.hasError)
                _stateBox(Icons.wifi_off, 'Could not load posts',
                    'Check your connection.',
                    onRetry: () => setState(
                        () => _posts = PostService.instance.watchActivePosts()))
              else if (posts.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          color: Colors.grey, size: 36),
                      const SizedBox(height: 10),
                      Text('No posts in this category yet',
                          style:
                              AppTheme.inter(size: 12, color: Colors.grey)),
                    ],
                  ),
                )
              else
                ...posts.map((p) => LoreCard(post: p)),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text.toUpperCase(),
      style: AppTheme.orbitron(size: 12, letterSpacing: 1));

  Widget _fandomSection() => FutureBuilder<List<Fandom>>(
        future: _fandoms,
        builder: (context, snap) {
          if (snap.hasError) {
            debugPrint('Category fandoms load error: ${snap.error}');
            return _stateBox(Icons.wifi_off, 'Could not load fandoms',
                'Check your connection and try again.',
                onRetry: () => setState(() => _fandoms = _loadFandoms()));
          }
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.cyan),
              ),
            );
          }
          final all = snap.data ?? [];
          if (all.isEmpty) {
            return _stateBox(Icons.hub_outlined, 'No fandoms here yet',
                'Fandoms for ${category.name} will appear here soon.');
          }
          final shown = _controller.search(all, _query);
          final trending = topTrendingIds(all, DateTime.now());
          return Column(
            children: [
              _searchBox(),
              const SizedBox(height: 12),
              if (shown.isEmpty)
                _stateBox(Icons.search_off, 'No fandoms match "${_query.trim()}"',
                    'Try a different name or tag.')
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 256,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: shown.length,
                  itemBuilder: (context, i) => _fandomCard(shown[i],
                      trending: trending.contains(shown[i].id)),
                ),
            ],
          );
        },
      );

  Widget _searchBox() => TextField(
        controller: _searchCtr,
        style: AppTheme.inter(size: 13, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search fandoms or tags…',
          hintStyle: AppTheme.inter(size: 13, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                  onPressed: () => _searchCtr.clear(),
                ),
          filled: true,
          fillColor: AppTheme.card,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.cyan)),
        ),
      );

  Widget _fandomCard(Fandom f, {bool trending = false}) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FandomPageScreen(fandomId: f.id, initial: f)),
        ),
        child: Container(
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
                height: 92,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    f.coverImageUrl.isEmpty
                        ? _coverFallback()
                        : Image.network(f.coverImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, e, st) => _coverFallback()),
                    Positioned(
                      left: 10,
                      bottom: 8,
                      child: FandomLogo(fandom: f, size: 36),
                    ),
                    if (trending)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded,
                                  color: Colors.black, size: 11),
                              const SizedBox(width: 3),
                              Text('Trending',
                                  style: AppTheme.inter(
                                      size: 9,
                                      color: Colors.black,
                                      weight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.orbitron(
                            size: 11, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(followersLabel(f.followerCount),
                        style: AppTheme.inter(size: 10, color: Colors.grey)),
                    if (f.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final t in f.tags.take(2)) ...[
                            Flexible(child: FandomTagChip(tag: t)),
                            const SizedBox(width: 4),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    FollowButton(fandomId: f.id, compact: true),
                  ],
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

  Widget _stateBox(IconData icon, String title, String subtitle,
          {VoidCallback? onRetry}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(size: 12, color: Colors.white70)),
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
        ),
      );

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: category.imageUrl != null && category.imageUrl!.isNotEmpty
              ? Image.network(
                  category.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, st) => _headerFallback(),
                )
              : _headerFallback(),
        ),
        const SizedBox(height: 12),
        Text(category.name, style: AppTheme.orbitron(size: 16)),
        if (category.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(category.description,
              style: AppTheme.inter(size: 12, color: Colors.grey, height: 1.4)),
        ],
      ],
    );
  }

  Widget _headerFallback() => Container(
        height: 140,
        width: double.infinity,
        color: AppTheme.card,
        alignment: Alignment.center,
        child: const Icon(Icons.category_outlined,
            color: Colors.white24, size: 40),
      );
}
