import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../services/category_service.dart';
import '../../theme/app_theme.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCategory>>(
      stream: CategoryService.instance.watchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.orange));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: AppTheme.inter(color: Colors.red)));
        }
        final cats = snapshot.data ?? [];
        return Column(
          children: [
            _header(context),
            Expanded(
              child: cats.isEmpty ? _empty() : _list(context, cats),
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
            Text('Categories', style: AppTheme.orbitron(size: 13)),
            ElevatedButton.icon(
              onPressed: () => _showDialog(context, null),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text('ADD', style: AppTheme.orbitron(size: 9)),
            ),
          ],
        ),
      );

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, color: Colors.grey, size: 36),
            const SizedBox(height: 12),
            Text('No categories yet',
                style: AppTheme.inter(size: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Tap ADD to create the first one',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
          ],
        ),
      );

  Widget _list(BuildContext context, List<AppCategory> cats) =>
      ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        separatorBuilder: (context, i) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _row(context, cats[i]),
      );

  Widget _row(BuildContext context, AppCategory cat) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(cat.icon, color: AppTheme.orange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name,
                      style: AppTheme.orbitron(
                          size: 11, weight: FontWeight.w700)),
                  Text('key: ${cat.key}  •  order ${cat.order}',
                      style: AppTheme.inter(size: 10, color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppTheme.cyan, size: 18),
              onPressed: () => _showDialog(context, cat),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 18),
              onPressed: () => _confirmDelete(context, cat),
              tooltip: 'Delete',
            ),
          ],
        ),
      );

  Future<void> _showDialog(BuildContext context, AppCategory? existing) =>
      showDialog(
        context: context,
        builder: (_) => _CategoryDialog(existing: existing),
      );

  Future<void> _confirmDelete(
      BuildContext context, AppCategory cat) async {
    final usage = await CategoryService.instance.checkUsage(cat.key);
    final total = (usage['posts'] ?? 0) +
        (usage['merchandise'] ?? 0) +
        (usage['fandoms'] ?? 0);
    if (!context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${cat.name}"?',
            style: AppTheme.orbitron(size: 12, color: Colors.white)),
        content: total > 0
            ? Text(
                'Still referenced by:\n'
                '  • ${usage['posts']} post(s)\n'
                '  • ${usage['merchandise']} merchandise item(s)\n'
                '  • ${usage['fandoms']} fandom(s)\n\n'
                'Deleting orphans those references. Continue?',
                style: AppTheme.inter(size: 12, color: Colors.grey))
            : Text('Remove this category? This cannot be undone.',
                style: AppTheme.inter(size: 12, color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL',
                style: AppTheme.orbitron(size: 9, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DELETE',
                style: AppTheme.orbitron(
                    size: 9, color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CategoryService.instance.deleteCategory(cat.id);
    }
  }
}

// ── Add / Edit dialog ─────────────────────────────────────────────────────────

class _CategoryDialog extends StatefulWidget {
  final AppCategory? existing;
  const _CategoryDialog({this.existing});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameCtr;
  late final TextEditingController _keyCtr;
  late final TextEditingController _orderCtr;
  String _icon = 'category';
  bool _saving = false;
  bool _keyEdited = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtr = TextEditingController(text: e?.name ?? '');
    _keyCtr = TextEditingController(text: e?.key ?? '');
    _orderCtr = TextEditingController(text: e?.order.toString() ?? '0');
    _icon = e?.iconName ?? 'category';
    if (e != null) _keyEdited = true;

    _nameCtr.addListener(() {
      if (!_keyEdited) {
        _keyCtr.text = _nameCtr.text
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      }
    });
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _keyCtr.dispose();
    _orderCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      backgroundColor: AppTheme.card,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Category' : 'New Category',
          style: AppTheme.orbitron(size: 13, color: Colors.white)),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('Name', _nameCtr, hint: 'Anime & Manga'),
              const SizedBox(height: 10),
              _field('Key (unique slug)', _keyCtr,
                  hint: 'anime',
                  readOnly: isEdit,
                  onChanged: (_) => _keyEdited = true),
              const SizedBox(height: 10),
              _field('Display order', _orderCtr,
                  hint: '0',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              Text('Icon',
                  style: AppTheme.inter(size: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppCategory.iconMap.entries.map((e) {
                  final sel = _icon == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = e.key),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.orange.withValues(alpha: 0.18)
                            : AppTheme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              sel ? AppTheme.orange : AppTheme.border,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Icon(e.value,
                          color:
                              sel ? AppTheme.orange : Colors.grey,
                          size: 20),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL',
              style: AppTheme.orbitron(size: 9, color: Colors.grey)),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.orange))
              : Text('SAVE',
                  style:
                      AppTheme.orbitron(size: 9, color: AppTheme.orange)),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool readOnly = false,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.inter(size: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            readOnly: readOnly,
            onChanged: onChanged,
            keyboardType: keyboardType,
            style: AppTheme.inter(
                size: 13,
                color: readOnly ? Colors.grey : Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppTheme.bg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppTheme.orange)),
            ),
          ),
        ],
      );

  Future<void> _save() async {
    final name = _nameCtr.text.trim();
    final key = _keyCtr.text.trim();
    final order = int.tryParse(_orderCtr.text.trim()) ?? 0;
    if (name.isEmpty || key.isEmpty) return;

    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await CategoryService.instance.addCategory(AppCategory(
          id: key,
          key: key,
          name: name,
          iconName: _icon,
          order: order,
        ));
      } else {
        await CategoryService.instance.updateCategory(
          widget.existing!
              .copyWith(name: name, iconName: _icon, order: order),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }
}
