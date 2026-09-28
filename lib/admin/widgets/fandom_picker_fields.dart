import 'package:flutter/material.dart';
import '../../models/fandom.dart';
import '../../services/fandom_service.dart';
import '../../theme/app_theme.dart';
import 'category_picker_field.dart';

Widget _fieldLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(text, style: AppTheme.inter(size: 12, color: Colors.grey)),
);

class CategoryFandomPicker extends StatefulWidget {
  final String? initialCategory;
  final String? initialFandomId;
  final bool fandomOptional;
  final String noneLabel;
  final Color accentColor;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<Fandom?> onFandomChanged;

  const CategoryFandomPicker({
    super.key,
    this.initialCategory,
    this.initialFandomId,
    this.fandomOptional = false,
    this.noneLabel = 'None',
    this.accentColor = AppTheme.cyan,
    required this.onCategoryChanged,
    required this.onFandomChanged,
  });

  @override
  State<CategoryFandomPicker> createState() => _CategoryFandomPickerState();
}

class _CategoryFandomPickerState extends State<CategoryFandomPicker> {
  static const String _none = '';
  String? _category;
  String? _fandomId;
  List<Fandom> _fandoms = [];
  bool _loading = false;
  String? _error;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    if (_category != null) {
      _load(_category!, keepFandomId: widget.initialFandomId);
    }
  }

  void _onCategoryChanged(String? key) {
    if (key == _category) return;
    final hadFandom = _fandomId != null;
    setState(() {
      _category = key;
      _fandomId = null;
      _fandoms = [];
      _error = null;
      _loading = false;
    });
    widget.onCategoryChanged(key);
    if (hadFandom) widget.onFandomChanged(null);
    if (key != null) _load(key);
  }

  Future<void> _load(String categoryKey, {String? keepFandomId}) async {
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await FandomService.instance.getByCategory(categoryKey);
      if (keepFandomId != null && !list.any((f) => f.id == keepFandomId)) {
        final current = await FandomService.instance.getById(keepFandomId);
        if (current != null && current.categoryId == categoryKey) {
          list.add(current);
        }
      }
      if (!mounted || seq != _loadSeq) return;
      final kept = keepFandomId == null
          ? null
          : list.where((f) => f.id == keepFandomId).firstOrNull;
      setState(() {
        _fandoms = list;
        _loading = false;
        if (kept != null) _fandomId = kept.id;
      });
      if (kept != null) widget.onFandomChanged(kept);
    } catch (e) {
      debugPrint('Fandoms load failed: $e');
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _loading = false;
        _error = 'Could not load fandoms. Check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? disabledHint;
    if (_category == null) {
      disabledHint = 'Select a category first';
    } else if (_loading) {
      disabledHint = 'Loading fandoms…';
    } else if (_error != null) {
      disabledHint = _error;
    } else if (_fandoms.isEmpty) {
      disabledHint =
          'No fandoms in this category yet. Add one in Fandoms first.';
    } else {
      disabledHint = null;
    }
    final enabled = disabledHint == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Category'),
        CategoryPickerField(
          value: _category,
          accentColor: widget.accentColor,
          onChanged: _onCategoryChanged,
        ),
        const SizedBox(height: 16),
        _fieldLabel(widget.fandomOptional ? 'Fandom (optional)' : 'Fandom'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButton<String>(
            key: ValueKey('fandoms-$_category'),
            value: enabled
                ? (_fandomId ?? (widget.fandomOptional ? _none : null))
                : null,
            isExpanded: true,
            dropdownColor: AppTheme.card,
            underline: const SizedBox.shrink(),
            style: AppTheme.inter(size: 13, color: Colors.white),
            hint: Text(
              'Select fandom',
              style: AppTheme.inter(size: 13, color: Colors.grey),
            ),
            disabledHint: Text(
              disabledHint ?? '',
              style: AppTheme.inter(size: 12, color: Colors.grey),
            ),
            items: [
              if (widget.fandomOptional)
                DropdownMenuItem(value: _none, child: Text(widget.noneLabel)),
              for (final f in _fandoms)
                DropdownMenuItem(
                  value: f.id,
                  child: Text(
                    f.isActive ? f.name : '${f.name} (inactive)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: enabled
                ? (v) {
                    final id = (v == null || v == _none) ? null : v;
                    setState(() => _fandomId = id);
                    widget.onFandomChanged(
                      _fandoms.where((f) => f.id == id).firstOrNull,
                    );
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class FandomMultiPicker extends StatefulWidget {
  final List<String> initialIds;
  final Color accentColor;
  final ValueChanged<List<String>> onChanged;

  const FandomMultiPicker({
    super.key,
    this.initialIds = const [],
    this.accentColor = AppTheme.cyan,
    required this.onChanged,
  });

  @override
  State<FandomMultiPicker> createState() => _FandomMultiPickerState();
}

class _FandomMultiPickerState extends State<FandomMultiPicker> {
  late final List<String> _selected = List.of(widget.initialIds);
  final Map<String, Fandom> _known = {};
  String? _category;
  List<Fandom> _options = [];
  bool _loading = false;
  String? _error;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    if (_selected.isNotEmpty) {
      FandomService.instance
          .getByIds(_selected)
          .then((list) {
            if (!mounted) return;
            setState(() {
              for (final f in list) {
                _known[f.id] = f;
              }
            });
          })
          .catchError((Object e) {
            debugPrint('Selected fandoms load failed: $e');
          });
    }
  }

  Future<void> _browse(String? key) async {
    final seq = ++_loadSeq;
    setState(() {
      _category = key;
      _options = [];
      _error = null;
      _loading = key != null;
    });
    if (key == null) return;
    try {
      final list = await FandomService.instance.getByCategory(key);
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _options = list;
        _loading = false;
        for (final f in list) {
          _known[f.id] = f;
        }
      });
    } catch (e) {
      debugPrint('Fandoms load failed: $e');
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _loading = false;
        _error = 'Could not load fandoms. Check your connection.';
      });
    }
  }

  void _toggle(String id, bool selected) {
    setState(() {
      _selected.remove(id);
      if (selected) _selected.add(id);
    });
    widget.onChanged(List.of(_selected));
  }

  String _nameOf(String id) {
    final f = _known[id];
    if (f == null) return id;
    return f.isActive ? f.name : '${f.name} (inactive)';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Fandoms at this event'),
        if (_selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'None selected — the event is not linked to a fandom.',
              style: AppTheme.inter(size: 11, color: Colors.grey),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final id in _selected)
                  InputChip(
                    label: Text(
                      _nameOf(id),
                      style: AppTheme.inter(size: 11, color: Colors.white),
                    ),
                    backgroundColor: AppTheme.card,
                    side: BorderSide(
                      color: widget.accentColor.withValues(alpha: 0.6),
                    ),
                    deleteIconColor: Colors.grey,
                    onDeleted: () => _toggle(id, false),
                  ),
              ],
            ),
          ),
        CategoryPickerField(
          value: _category,
          accentColor: widget.accentColor,
          onChanged: _browse,
        ),
        if (_category != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Material(
              color: AppTheme.card,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _error != null || _options.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _error ??
                            'No fandoms in this category yet. Add one in Fandoms first.',
                        style: AppTheme.inter(size: 12, color: Colors.grey),
                      ),
                    )
                  : Column(
                      children: [
                        for (final f in _options)
                          CheckboxListTile(
                            dense: true,
                            value: _selected.contains(f.id),
                            activeColor: widget.accentColor,
                            checkColor: Colors.black,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              f.name,
                              style: AppTheme.inter(
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                            onChanged: (v) => _toggle(f.id, v ?? false),
                          ),
                      ],
                    ),
            ),
          ),
      ],
    );
  }
}
