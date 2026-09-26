import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_category.dart';
import '../../models/glossary_term.dart';
import '../../services/category_service.dart';
import '../../services/glossary_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icons.dart';
import 'glossary_term_screen.dart';

const String _kArtwork = 'assets/images/onboarding/onboarding_bg.jpg';

/// Sentinel filter for terms with no category.
const String _kGeneral = '__general__';

/// Fandom Glossary: searchable, category-filterable terms from Firestore
/// (`glossary` via [GlossaryService]). Category keys are resolved to names
/// with [CategoryService]. Tap a term for its detail view.
class GlossaryScreen extends StatefulWidget {
  /// Test-only data overrides (default to Firestore).
  @visibleForTesting
  final Stream<List<GlossaryTerm>>? termsStream;
  @visibleForTesting
  final Stream<List<AppCategory>>? categoriesStream;

  const GlossaryScreen({super.key, this.termsStream, this.categoriesStream});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  // Created once — a new stream per build would re-subscribe on every keystroke.
  late final Stream<List<GlossaryTerm>> _terms =
      widget.termsStream ?? GlossaryService.instance.watchTerms();
  late final Stream<List<AppCategory>> _categories =
      widget.categoriesStream ?? CategoryService.instance.watchCategories();

  final _searchCtr = TextEditingController();
  String _query = '';
  String? _categoryFilter; // null = all

  @override
  void initState() {
    super.initState();
    _searchCtr.addListener(() {
      final q = _searchCtr.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

  void _open(GlossaryTerm term, List<GlossaryTerm> all, Map<String, AppCategory> cats) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlossaryTermScreen(term: term, allTerms: all, categoriesByKey: cats),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: StreamBuilder<List<AppCategory>>(
        stream: _categories,
        builder: (context, catSnap) {
          final catsByKey = {for (final c in catSnap.data ?? <AppCategory>[]) c.key: c};
          return StreamBuilder<List<GlossaryTerm>>(
            stream: _terms,
            builder: (context, snapshot) {
              return CustomScrollView(
                slivers: [
                  _header(),
                  SliverToBoxAdapter(child: _searchBar()),
                  if (snapshot.hasData && snapshot.data!.isNotEmpty)
                    SliverToBoxAdapter(child: _filters(snapshot.data!, catsByKey)),
                  ..._content(snapshot, catsByKey),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header() => SliverAppBar(
        pinned: true,
        expandedHeight: 170,
        backgroundColor: AppTheme.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Fandom Glossary', style: AppTheme.orbitron(size: 13)),
        flexibleSpace: FlexibleSpaceBar(
          collapseMode: CollapseMode.parallax,
          background: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(_kArtwork,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.3, -0.4),
                  errorBuilder: (ctx, e, st) => const SizedBox.shrink()),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.bg.withValues(alpha: 0.55),
                      AppTheme.bg.withValues(alpha: 0.6),
                      AppTheme.bg,
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [Color(0xFFC084FC), AppTheme.accent, AppTheme.cyan],
                      ).createShader(r),
                      child: Text('SPEAK FANDOM',
                          style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 4),
                    Text('The words every fan uses — explained simply.',
                        style: AppTheme.inter(size: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  // ── Search & filters ─────────────────────────────────────────────────────

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextField(
              controller: _searchCtr,
              style: AppTheme.inter(size: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search terms or meanings…',
                hintStyle: AppTheme.inter(size: 13, color: Colors.white38),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.cyan, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                        onPressed: _searchCtr.clear,
                      ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.cyan, width: 1.4)),
              ),
            ),
          ),
        ),
      );

  Widget _filters(List<GlossaryTerm> terms, Map<String, AppCategory> catsByKey) {
    // Only offer filters for categories that actually have terms.
    final keys = <String>{for (final t in terms) t.category.isEmpty ? _kGeneral : t.category};
    final ordered = keys.toList()
      ..sort((a, b) => _categoryLabel(a, catsByKey).compareTo(_categoryLabel(b, catsByKey)));
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        children: [
          _filterChip('All', Icons.apps_rounded, null, terms.length),
          for (final k in ordered)
            _filterChip(
              _categoryLabel(k, catsByKey),
              k == _kGeneral || catsByKey[k] == null
                  ? Icons.auto_awesome_rounded
                  : categoryIcon(catsByKey[k]!),
              k,
              terms.where((t) => (t.category.isEmpty ? _kGeneral : t.category) == k).length,
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, IconData icon, String? value, int count) {
    final selected = _categoryFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _categoryFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: selected
                ? LinearGradient(colors: [
                    AppTheme.accent.withValues(alpha: 0.55),
                    AppTheme.cyan.withValues(alpha: 0.3),
                  ])
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
                color: selected ? AppTheme.accent : Colors.white.withValues(alpha: 0.12)),
            boxShadow: selected
                ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.35), blurRadius: 10)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : AppTheme.cyan),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTheme.inter(
                      size: 12,
                      color: selected ? Colors.white : Colors.white70,
                      weight: selected ? FontWeight.w700 : FontWeight.w500)),
              const SizedBox(width: 6),
              Text('$count',
                  style: AppTheme.inter(
                      size: 10, color: selected ? Colors.white70 : Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Results ──────────────────────────────────────────────────────────────

  List<Widget> _content(
      AsyncSnapshot<List<GlossaryTerm>> snapshot, Map<String, AppCategory> catsByKey) {
    if (snapshot.hasError) {
      return [
        _stateSliver(Icons.wifi_off_rounded, 'Could not load the glossary',
            'Check your connection and try again.'),
      ];
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
        _stateSliver(Icons.menu_book_outlined, 'No terms yet',
            'Check back soon for fandom terminology.'),
      ];
    }
    final filtered = all.where((t) {
      final key = t.category.isEmpty ? _kGeneral : t.category;
      if (_categoryFilter != null && key != _categoryFilter) return false;
      if (_query.isEmpty) return true;
      return t.term.toLowerCase().contains(_query) ||
          t.definition.toLowerCase().contains(_query);
    }).toList();
    if (filtered.isEmpty) {
      return [
        _stateSliver(
          Icons.search_off_rounded,
          _query.isEmpty ? 'No terms in this category' : 'No terms match "${_searchCtr.text.trim()}"',
          'Try another word or clear the filters.',
          action: TextButton(
            onPressed: () {
              _searchCtr.clear();
              setState(() => _categoryFilter = null);
            },
            child: Text('CLEAR FILTERS', style: AppTheme.orbitron(size: 9, color: AppTheme.cyan)),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverToBoxAdapter(
          child: Text(
            '${filtered.length} term${filtered.length == 1 ? '' : 's'}',
            style: AppTheme.inter(size: 11, color: Colors.white38),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 460,
            mainAxisExtent: 112,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => _FadeIn(
              key: ValueKey('${filtered[i].id}|$_categoryFilter'),
              delayMs: (i * 40).clamp(0, 400),
              child: _GlossaryTermCard(
                term: filtered[i],
                categoryLabel: filtered[i].category.isEmpty
                    ? null
                    : _categoryLabel(filtered[i].category, catsByKey),
                onTap: () => _open(filtered[i], all, catsByKey),
              ),
            ),
            childCount: filtered.length,
          ),
        ),
      ),
    ];
  }

  String _categoryLabel(String key, Map<String, AppCategory> catsByKey) =>
      key == _kGeneral ? 'General' : (catsByKey[key]?.name ?? key);

  Widget _stateSliver(IconData icon, String title, String subtitle, {Widget? action}) =>
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white38, size: 36),
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

/// Glass card: term, category, short definition.
class _GlossaryTermCard extends StatelessWidget {
  final GlossaryTerm term;
  final String? categoryLabel;
  final VoidCallback onTap;

  const _GlossaryTermCard({
    required this.term,
    required this.categoryLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                AppTheme.accent.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Hero(
                            tag: 'glossary-term-${term.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(term.term,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        if (categoryLabel != null) ...[
                          const SizedBox(width: 8),
                          _CategoryBadge(label: categoryLabel!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      term.definition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 12, color: Colors.white70, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: AppTheme.cyan.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 130),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.cyan.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.inter(size: 9.5, color: AppTheme.cyan, weight: FontWeight.w600)),
      );
}

/// Staggered fade + rise when a card first appears.
class _FadeIn extends StatelessWidget {
  final int delayMs;
  final Widget child;
  const _FadeIn({super.key, required this.delayMs, required this.child});

  @override
  Widget build(BuildContext context) {
    final total = 320 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
      ),
    );
  }
}
