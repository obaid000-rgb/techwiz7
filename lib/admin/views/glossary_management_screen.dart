import 'package:flutter/material.dart';
import '../../models/glossary_term.dart';
import '../../services/glossary_service.dart';
import '../../theme/app_theme.dart';
import 'glossary_form_screen.dart';

class GlossaryManagementScreen extends StatefulWidget {
  const GlossaryManagementScreen({super.key});

  @override
  State<GlossaryManagementScreen> createState() => _GlossaryManagementScreenState();
}

class _GlossaryManagementScreenState extends State<GlossaryManagementScreen> {
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
    return StreamBuilder<List<GlossaryTerm>>(
      stream: GlossaryService.instance.watchTerms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
        }
        if (snapshot.hasError) {
          debugPrint('Glossary load error: ${snapshot.error}');
          return Center(
              child: Text('Could not load glossary terms. Check your connection and try again.', style: AppTheme.inter(color: Colors.red)));
        }
        final terms = snapshot.data ?? [];
        final filtered = _query.isEmpty
            ? terms
            : terms.where((t) => t.term.toLowerCase().contains(_query)).toList();

        return Column(
          children: [
            _header(context),
            _searchBox(),
            Expanded(
              child: terms.isEmpty
                  ? _empty()
                  : filtered.isEmpty
                      ? _noResults()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) => _termRow(context, filtered[i]),
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Glossary', style: AppTheme.orbitron(size: 13)),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlossaryFormScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text('ADD', style: AppTheme.orbitron(size: 9)),
            ),
          ],
        ),
      );

  Widget _searchBox() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: TextField(
          controller: _searchCtr,
          style: AppTheme.inter(size: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search terms…',
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accent)),
          ),
        ),
      );

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined, color: Colors.grey, size: 36),
            const SizedBox(height: 12),
            Text('No glossary terms yet', style: AppTheme.inter(size: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Tap ADD to create the first one',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
          ],
        ),
      );

  Widget _noResults() => Center(
        child: Text('No terms match "${_searchCtr.text.trim()}"',
            style: AppTheme.inter(size: 12, color: Colors.grey)),
      );

  Widget _termRow(BuildContext context, GlossaryTerm term) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(term.term,
                      style: AppTheme.orbitron(size: 11, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(term.definition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 11, color: Colors.grey)),
                  if (term.category.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text('category: ${term.category}',
                        style: AppTheme.inter(size: 9, color: Colors.white38)),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.cyan, size: 18),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GlossaryFormScreen(existing: term)),
              ),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              onPressed: () => _confirmDelete(context, term),
              tooltip: 'Delete',
            ),
          ],
        ),
      );

  Future<void> _confirmDelete(BuildContext context, GlossaryTerm term) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${term.term}"?',
            style: AppTheme.orbitron(size: 12, color: Colors.white)),
        content: Text('This cannot be undone.',
            style: AppTheme.inter(size: 12, color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL', style: AppTheme.orbitron(size: 9, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DELETE', style: AppTheme.orbitron(size: 9, color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await GlossaryService.instance.deleteTerm(term.id);
    }
  }
}
