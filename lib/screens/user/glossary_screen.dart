import 'package:flutter/material.dart';
import '../../models/glossary_term.dart';
import '../../services/glossary_service.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fandom Glossary')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search terms...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<GlossaryTerm>>(
              stream: GlossaryService.streamTerms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const _MessageState(
                    icon: Icons.error_outline,
                    message: 'Could not load the glossary. Check your connection.',
                  );
                }

                final allTerms = snapshot.data ?? [];
                final filtered = _searchQuery.isEmpty
                    ? allTerms
                    : allTerms.where((t) => t.term.toLowerCase().contains(_searchQuery)).toList();

                if (filtered.isEmpty) {
                  return _MessageState(
                    icon: Icons.menu_book_outlined,
                    message: allTerms.isEmpty
                        ? 'No glossary terms have been added yet.'
                        : 'No terms match your search.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16161F),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.term,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          if (entry.definition.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              entry.definition,
                              style: TextStyle(color: Colors.white.withOpacity(0.65), height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MessageState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}