import 'package:flutter/material.dart';
import '../../../models/faq.dart';
import '../../../services/faq_service.dart';
import '../../../theme/app_theme.dart';
import 'faq_form_screen.dart';

class FaqManagementScreen extends StatelessWidget {
  const FaqManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Faq>>(
      stream: FaqService.instance.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
        }
        if (snapshot.hasError) {
          debugPrint('FAQ load error: ${snapshot.error}');
          return Center(
              child: Text('Could not load FAQs. Check your connection and try again.',
                  style: AppTheme.inter(color: Colors.red)));
        }
        final faqs = snapshot.data ?? [];
        return Column(
          children: [
            _header(context),
            if (faqs.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text('Drag the handle to change the order shown on Contact Us.',
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
              ),
            Expanded(
              child: faqs.isEmpty
                  ? Center(
                      child: Text('No FAQs yet. Tap ADD to write the first one.',
                          style: AppTheme.inter(size: 13, color: Colors.grey)),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      buildDefaultDragHandles: false,
                      itemCount: faqs.length,
                      // ignore: deprecated_member_use
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final reordered = List<Faq>.from(faqs);
                        reordered.insert(newIndex, reordered.removeAt(oldIndex));
                        FaqService.instance.reorder(reordered).catchError((Object e) {
                          debugPrint('FAQ reorder failed: $e');
                        });
                      },
                      itemBuilder: (context, i) => _row(context, faqs[i], i),
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
            Text('FAQs', style: AppTheme.orbitron(size: 13)),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const FaqFormScreen())),
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

  Widget _row(BuildContext context, Faq faq, int index) => Container(
        key: ValueKey(faq.id),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(4, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: faq.isActive ? AppTheme.border : Colors.redAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(faq.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 13, weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(faq.answer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 11, color: Colors.grey)),
                  if (!faq.isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Hidden', style: AppTheme.inter(size: 10, color: Colors.redAccent)),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.cyan, size: 18),
              tooltip: 'Edit',
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => FaqFormScreen(existing: faq))),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, faq),
            ),
          ],
        ),
      );

  Future<void> _confirmDelete(BuildContext context, Faq faq) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete this FAQ?', style: AppTheme.orbitron(size: 12, color: Colors.white)),
        content: Text(faq.question, style: AppTheme.inter(size: 12, color: Colors.grey)),
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
    if (ok != true) return;
    try {
      await FaqService.instance.delete(faq.id);
    } catch (e) {
      debugPrint('FAQ delete failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete. Check your connection.')));
      }
    }
  }
}
