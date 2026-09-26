import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_category.dart';
import '../../models/glossary_term.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icons.dart';
import 'category_detail_screen.dart';

/// Detail view for one glossary term: full definition, its category (tap to
/// open that fandom), and other terms from the same category.
class GlossaryTermScreen extends StatelessWidget {
  final GlossaryTerm term;
  final List<GlossaryTerm> allTerms;
  final Map<String, AppCategory> categoriesByKey;

  const GlossaryTermScreen({
    super.key,
    required this.term,
    required this.allTerms,
    required this.categoriesByKey,
  });

  @override
  Widget build(BuildContext context) {
    final category = term.category.isEmpty ? null : categoriesByKey[term.category];
    final related = term.category.isEmpty
        ? const <GlossaryTerm>[]
        : allTerms.where((t) => t.category == term.category && t.id != term.id).take(8).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Glossary', style: AppTheme.orbitron(size: 13)),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _glow(AppTheme.accent, 300),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _glow(AppTheme.cyan, 280),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text('TERM', style: AppTheme.orbitron(size: 10, color: AppTheme.cyan, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Hero(
                    tag: 'glossary-term-${term.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(term.term,
                          style: GoogleFonts.orbitron(
                              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          AppTheme.accent.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(color: AppTheme.accent.withValues(alpha: 0.15), blurRadius: 20),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.cyan, size: 16),
                            const SizedBox(width: 8),
                            Text('What it means',
                                style: AppTheme.inter(
                                    size: 12, color: AppTheme.cyan, weight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SelectableText(term.definition,
                            style: AppTheme.inter(size: 15, color: Colors.white, height: 1.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _label('CATEGORY'),
                  const SizedBox(height: 8),
                  _categoryTile(context, category),
                  if (related.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _label('MORE FROM ${(category?.name ?? term.category).toUpperCase()}'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in related)
                          ActionChip(
                            label: Text(r.term),
                            avatar: const Icon(Icons.north_east_rounded, size: 14, color: AppTheme.cyan),
                            labelStyle: AppTheme.inter(size: 12, color: Colors.white),
                            backgroundColor: Colors.white.withValues(alpha: 0.06),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GlossaryTermScreen(
                                  term: r,
                                  allTerms: allTerms,
                                  categoriesByKey: categoriesByKey,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: AppTheme.orbitron(size: 10, color: Colors.white54, letterSpacing: 1.5));

  Widget _categoryTile(BuildContext context, AppCategory? category) {
    if (term.category.isEmpty) {
      return _plainTile(Icons.auto_awesome_rounded, 'General fandom term',
          'Used across many fandoms.');
    }
    if (category == null) {
      return _plainTile(Icons.category_outlined, term.category, 'This category is no longer available.');
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: category.isActive
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: category)),
                )
            : null,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppTheme.card,
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.orange.withValues(alpha: 0.15),
                ),
                child: Icon(categoryIcon(category), color: AppTheme.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name,
                        style: AppTheme.inter(size: 14, color: Colors.white, weight: FontWeight.w700)),
                    if (category.description.isNotEmpty)
                      Text(category.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 11, color: Colors.white54)),
                  ],
                ),
              ),
              if (category.isActive) ...[
                Text('Explore', style: AppTheme.inter(size: 11, color: AppTheme.cyan)),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.cyan),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _plainTile(IconData icon, String title, String subtitle) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.card,
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.inter(size: 14, color: Colors.white, weight: FontWeight.w700)),
                  Text(subtitle, style: AppTheme.inter(size: 11, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _glow(Color color, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0),
            ]),
          ),
        ),
      );
}
