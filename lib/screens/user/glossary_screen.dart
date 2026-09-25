import 'package:flutter/material.dart';
import '../../models/glossary_term.dart';
import '../../services/glossary_service.dart';
import '../../theme/app_theme.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final _searchCtr = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtr.addListener(() {
      setState(() => _query = _searchCtr.text.trim().toLowerCase());
    });
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Fandom Glossary', style: AppTheme.orbitron(size: 13)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtr,
              style: AppTheme.inter(size: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search terms…',
                hintStyle: AppTheme.inter(size: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                filled: true,
                fillColor: AppTheme.card,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            ),
          ),
          Expanded(
            child: StreamBuilder<List<GlossaryTerm>>(
              stream: GlossaryService.instance.watchTerms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.grey, size: 28),
                        const SizedBox(height: 8),
                        Text('Could not load the glossary',
                            style: AppTheme.inter(size: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }
                final terms = snapshot.data ?? [];
                if (terms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book_outlined, color: Colors.grey, size: 36),
                        const SizedBox(height: 10),
                        Text('No terms yet',
                            style: AppTheme.orbitron(
                                size: 12, color: Colors.grey, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Check back soon for fandom terminology.',
                            style: AppTheme.inter(size: 11, color: Colors.grey)),
                      ],
                    ),
                  );
                }
                final filtered = _query.isEmpty
                    ? terms
                    : terms.where((t) => t.term.toLowerCase().contains(_query)).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text('No terms match "${_searchCtr.text.trim()}"',
                        style: AppTheme.inter(size: 12, color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _termCard(filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _termCard(GlossaryTerm term) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(term.term,
                      style: AppTheme.orbitron(size: 13, weight: FontWeight.w700)),
                ),
                if (term.category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(term.category,
                        style: AppTheme.inter(size: 9, color: AppTheme.accent)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(term.definition,
                style: AppTheme.inter(size: 12, color: Colors.white70, height: 1.4)),
          ],
        ),
      );
}
