import 'dart:async';
import 'package:flutter/material.dart';
import '../../../logic/glossary_query.dart';
import '../../../models/app_category.dart';
import '../../../models/glossary_term.dart';
import '../../../services/category_service.dart';
import '../../../services/glossary_service.dart';
import '../../../theme/app_theme.dart';
import 'glossary_form_screen.dart';

class GlossaryManagementScreen extends StatefulWidget {
  const GlossaryManagementScreen({super.key});

  @override
  State<GlossaryManagementScreen> createState() => _GlossaryManagementScreenState();
}

class _GlossaryManagementScreenState extends State<GlossaryManagementScreen> {
  final _searchCtr = TextEditingController();
  // The search text the results use, updated 250 ms after the last
  // keystroke. Only the results list listens to it: typing never rebuilds
  // the header, the search bar or the data streams.
  final _query = ValueNotifier<String>('');
  Timer? _debounce;
  // Created once. Building the stream inside build() made every keystroke
  // start a new Firestore listener, which reset the list to "loading" and
  // replaced the search box on each letter.
  late final Stream<List<GlossaryTerm>> _terms = GlossaryService.instance.watchTerms();
  late final Stream<List<AppCategory>> _categories = CategoryService.instance.watchCategories();

  @override
  void initState() {
    super.initState();
    _searchCtr.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () => _query.value = _searchCtr.text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtr.dispose();
    _query.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtr.clear();
    _query.value = '';
  }

  @override
  Widget build(BuildContext context) {
    // The header and search box sit outside the StreamBuilders, so live
    // Firestore updates never rebuild or reset them.
    return Column(
      children: [
        _header(context),
        _searchBox(),
        Expanded(
          child: StreamBuilder<List<AppCategory>>(
            stream: _categories,
            builder: (context, catSnap) {
              final names = {for (final c in catSnap.data ?? const <AppCategory>[]) c.key: c.name};
              return StreamBuilder<List<GlossaryTerm>>(
                stream: _terms,
                builder: (context, snapshot) {
                  if (snapshot.hasError && !snapshot.hasData) {
                    debugPrint('Glossary load error: ${snapshot.error}');
                    return Center(
                        child: Text('Could not load glossary terms. Check your connection and try again.',
                            style: AppTheme.inter(color: Colors.red)));
                  }
                  // Spinner only before the very first data; afterwards the
                  // last list stays on screen while updates arrive.
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
                  }
                  final terms = snapshot.data!;
                  if (terms.isEmpty) return _empty();
                  return ValueListenableBuilder<String>(
                    valueListenable: _query,
                    builder: (context, query, _) {
                      final filtered = filterGlossary(terms, query, names);
                      if (filtered.isEmpty) return _noResults(query);
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _termRow(context, filtered[i], names),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
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
          textInputAction: TextInputAction.search,
          // The keyboard's search key only closes the keyboard; the text stays.
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          style: AppTheme.inter(size: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search terms, definitions, categories…',
            hintStyle: AppTheme.inter(size: 13, color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
            // Rebuilds only this button as the text changes.
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchCtr,
              builder: (context, value, _) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                      onPressed: _clearSearch,
                    ),
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

  Widget _noResults(String query) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.grey, size: 32),
            const SizedBox(height: 10),
            Text('No terms match "${query.trim()}"',
                textAlign: TextAlign.center,
                style: AppTheme.inter(size: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear, size: 16, color: AppTheme.cyan),
              label: Text('Clear search', style: AppTheme.inter(size: 12, color: AppTheme.cyan)),
            ),
          ],
        ),
      );

  Widget _termRow(BuildContext context, GlossaryTerm term, Map<String, String> names) => Container(
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
                    Text('Category: ${names[term.category] ?? term.category}',
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
    if (confirm != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await GlossaryService.instance.deleteTerm(term.id);
    } catch (e) {
      debugPrint('Glossary delete failed: $e');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Could not delete. Check your connection.')));
    }
  }
}
