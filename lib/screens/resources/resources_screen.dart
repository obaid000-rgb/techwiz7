import 'package:flutter/material.dart';
import '../../controllers/resources/resource_controller.dart';
import '../../logic/resource_query.dart';
import '../../models/creator.dart';
import '../../models/fandom.dart';
import '../../models/post.dart';
import '../../services/resource_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/creator_widgets.dart';
import '../../widgets/lore_card.dart';
import '../fandoms/fandom_page_screen.dart';

class ResourcesScreen extends StatefulWidget {
  final ResourceFilter? initialFilter;
  final ResourceRepository repository;

  const ResourcesScreen({
    super.key,
    this.initialFilter,
    this.repository = const FirestoreResourceRepository(),
  });

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  late final ResourceController _c = ResourceController(
    repository: widget.repository,
    initialFilter: widget.initialFilter,
  );
  late final TextEditingController _searchCtr =
      TextEditingController(text: widget.initialFilter?.query ?? '');

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    _searchCtr.dispose();
    super.dispose();
  }

  // ── Labels ────────────────────────────────────────────────────────────────

  String _categoryName(String id) =>
      _c.data?.categories.where((c) => c.key == id).firstOrNull?.name ?? id;
  String _fandomName(String id) =>
      _c.data?.fandoms.where((f) => f.id == id).firstOrNull?.name ?? id;
  String _creatorName(String id) =>
      _c.data?.creators.where((c) => c.id == id).firstOrNull?.name ?? id;

  List<({String label, ResourceFilter Function(ResourceFilter) remove})>
      _activeChips(ResourceFilter f) => [
            for (final t in f.types)
              (label: t, remove: (x) => x.copyWith(types: {...x.types}..remove(t))),
            for (final c in f.categoryIds)
              (
                label: _categoryName(c),
                remove: (x) =>
                    x.copyWith(categoryIds: {...x.categoryIds}..remove(c))
              ),
            for (final id in f.fandomIds)
              (
                label: _fandomName(id),
                remove: (x) => x.copyWith(fandomIds: {...x.fandomIds}..remove(id))
              ),
            for (final id in f.creatorIds)
              (
                label: _creatorName(id),
                remove: (x) =>
                    x.copyWith(creatorIds: {...x.creatorIds}..remove(id))
              ),
            if (f.myInterestsOnly)
              (label: 'My interests', remove: (x) => x.copyWith(myInterestsOnly: false)),
            if (f.sort != ResourceSort.newest)
              (
                label: 'Sort: ${kResourceSortLabels[f.sort]}',
                remove: (x) => x.copyWith(sort: ResourceSort.newest)
              ),
          ];

  // ── Build ─────────────────────────────────────────────────────────────────

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
        title: Text('Resources', style: AppTheme.orbitron(size: 13)),
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          if (!_c.hasData) {
            if (_c.error != null && !_c.loading) {
              return _stateBox(Icons.wifi_off, 'Could not load resources',
                  'Check your connection and try again.',
                  action: ('Try again', _c.load));
            }
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.cyan));
          }
          return RefreshIndicator(
            color: AppTheme.cyan,
            backgroundColor: AppTheme.card,
            onRefresh: _c.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header()),
                ..._resultSlivers(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    final f = _c.filter;
    final chips = _activeChips(f);
    final fandoms = _c.matchingFandoms;
    final count = _c.results.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _searchBox(),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final chip in chips)
                  InputChip(
                    label: Text(chip.label,
                        style: AppTheme.inter(size: 11, color: Colors.white)),
                    backgroundColor: AppTheme.accent.withValues(alpha: 0.18),
                    side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5)),
                    deleteIconColor: Colors.white70,
                    visualDensity: VisualDensity.compact,
                    onDeleted: () => _c.setFilter(chip.remove(_c.filter)),
                  ),
                TextButton(
                  onPressed: _c.clearAll,
                  child: Text('Clear all',
                      style: AppTheme.inter(size: 12, color: AppTheme.cyan)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _typeSelector(),
          const SizedBox(height: 10),
          Row(
            children: [
              FilterChip(
                avatar: Icon(Icons.favorite_rounded,
                    size: 16,
                    color: f.myInterestsOnly ? Colors.black : AppTheme.pink),
                label: Text('My interests',
                    style: AppTheme.inter(
                        size: 12,
                        weight: FontWeight.w600,
                        color: f.myInterestsOnly ? Colors.black : Colors.white)),
                selected: f.myInterestsOnly,
                showCheckmark: false,
                selectedColor: AppTheme.pink,
                backgroundColor: AppTheme.card,
                side: BorderSide(
                    color: f.myInterestsOnly ? AppTheme.pink : AppTheme.border),
                onSelected: _c.setMyInterests,
              ),
              const Spacer(),
              Badge(
                isLabelVisible: f.activeCount > 0,
                label: Text('${f.activeCount}'),
                backgroundColor: AppTheme.cyan,
                textColor: Colors.black,
                child: OutlinedButton.icon(
                  onPressed: _openFilterSheet,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.tune_rounded,
                      size: 16, color: AppTheme.cyan),
                  label: Text('Filter',
                      style: AppTheme.inter(size: 12, color: Colors.white)),
                ),
              ),
            ],
          ),
          if (fandoms.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('FANDOMS',
                style: AppTheme.orbitron(size: 10, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fandoms.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => _fandomChip(fandoms[i]),
              ),
            ),
          ],
          CreatorBubbleRow(
            title: 'CREATORS',
            creators: _c.matchingCreators,
            padding: const EdgeInsets.only(top: 14),
          ),
          const SizedBox(height: 14),
          Text('$count resource${count == 1 ? '' : 's'}',
              style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _searchBox() => TextField(
        controller: _searchCtr,
        onChanged: (v) {
          _c.setQuery(v);
          setState(() {});
        },
        textInputAction: TextInputAction.search,
        style: AppTheme.inter(size: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search news, videos, podcasts, fandoms',
          hintStyle: AppTheme.inter(size: 13, color: Colors.grey),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.cyan, size: 20),
          suffixIcon: _searchCtr.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                  onPressed: () {
                    _searchCtr.clear();
                    _c.setFilter(_c.filter.copyWith(query: ''));
                    setState(() {});
                  },
                ),
          filled: true,
          fillColor: AppTheme.card,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.cyan)),
        ),
      );

  Widget _typeSelector() {
    final types = _c.filter.types;
    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onTap(),
            showCheckmark: false,
            labelStyle: AppTheme.inter(
                size: 12,
                weight: FontWeight.w600,
                color: selected ? Colors.black : Colors.white70),
            selectedColor: AppTheme.cyan,
            backgroundColor: AppTheme.card,
            side: BorderSide(color: selected ? AppTheme.cyan : AppTheme.border),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', types.isEmpty, () => _c.setType(null)),
          for (final t in kPostContentTypes)
            chip(t, types.length == 1 && types.contains(t), () => _c.setType(t)),
        ],
      ),
    );
  }

  Widget _fandomChip(Fandom f) => Material(
        color: AppTheme.card,
        shape: StadiumBorder(side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FandomPageScreen(fandomId: f.id, initial: f)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FandomLogo(fandom: f, size: 30),
                const SizedBox(width: 8),
                Text(f.name,
                    style: AppTheme.inter(size: 12, weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

  List<Widget> _resultSlivers() {
    final results = _c.results;
    if (results.isNotEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          sliver: SliverList.builder(
            itemCount: results.length,
            itemBuilder: (context, i) =>
                LoreCard(key: ValueKey(results[i].id), post: results[i]),
          ),
        ),
      ];
    }
    final f = _c.filter;
    final Widget empty;
    if (f.myInterestsOnly) {
      empty = _stateBox(Icons.favorite_border, 'Nothing in your interests yet',
          _c.hasInterests
              ? 'There are no resources in your interest categories for these filters.'
              : 'You haven\'t picked any interest categories yet.',
          action: ('Show all', () => _c.setMyInterests(false)));
    } else {
      final labels = [
        if (f.query.trim().isNotEmpty) '"${f.query.trim()}"',
        for (final c in _activeChips(f)) c.label,
      ];
      empty = _stateBox(
        Icons.search_off_rounded,
        labels.isEmpty ? 'No resources yet' : 'No resources match',
        labels.isEmpty
            ? 'News, galleries, videos and podcasts will appear here.'
            : 'Nothing matches ${labels.join(' + ')}.',
        action: labels.isEmpty
            ? null
            : ('Clear all', () {
                _searchCtr.clear();
                _c.setFilter(const ResourceFilter());
                setState(() {});
              }),
      );
    }
    return [SliverToBoxAdapter(child: empty)];
  }

  Widget _stateBox(IconData icon, String title, String subtitle,
          {(String, VoidCallback)? action}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey, size: 36),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(
                      size: 14, color: Colors.white70, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(size: 12, color: Colors.grey)),
              if (action != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: action.$2,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.cyan),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(action.$1,
                      style: AppTheme.inter(size: 12, color: AppTheme.cyan)),
                ),
              ],
            ],
          ),
        ),
      );

  // ── Filter sheet ──────────────────────────────────────────────────────────

  Future<void> _openFilterSheet() async {
    final data = _c.data;
    if (data == null) return;
    var draft = _c.filter;
    final applied = await showModalBottomSheet<ResourceFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void update(ResourceFilter f) => setSheet(() => draft = f);
          final fandoms = draft.categoryIds.isEmpty
              ? data.fandoms
              : data.fandoms
                  .where((f) => draft.categoryIds.contains(f.categoryId))
                  .toList();
          final creators = _c.availableCreatorsFor(draft);
          final followed = _c.followedFandomIds
              .where((id) => data.fandoms.any((f) => f.id == id))
              .toSet();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            builder: (ctx, scroll) => Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                ),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    children: [
                      Text('Filter resources', style: AppTheme.orbitron(size: 13)),
                      const SizedBox(height: 16),
                      _sheetTitle('Categories'),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c in data.categories)
                            _sheetChip(c.name, draft.categoryIds.contains(c.key), (on) {
                              final cats = {...draft.categoryIds};
                              on ? cats.add(c.key) : cats.remove(c.key);
                              final keep = cats.isEmpty
                                  ? draft.fandomIds
                                  : draft.fandomIds
                                      .where((id) => data.fandoms.any((f) =>
                                          f.id == id && cats.contains(f.categoryId)))
                                      .toSet();
                              update(draft.copyWith(categoryIds: cats, fandomIds: keep));
                            }),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: _sheetTitle('Fandoms')),
                          if (_c.isSignedIn && followed.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => update(draft.copyWith(
                                  fandomIds: {...draft.fandomIds, ...followed})),
                              icon: const Icon(Icons.favorite_rounded,
                                  size: 14, color: AppTheme.pink),
                              label: Text('Fandoms I follow',
                                  style: AppTheme.inter(size: 12, color: AppTheme.pink)),
                            ),
                        ],
                      ),
                      if (fandoms.isEmpty)
                        Text('No fandoms in the selected categories.',
                            style: AppTheme.inter(size: 12, color: Colors.grey))
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final f in fandoms)
                              _sheetChip(f.name, draft.fandomIds.contains(f.id), (on) {
                                final ids = {...draft.fandomIds};
                                on ? ids.add(f.id) : ids.remove(f.id);
                                update(draft.copyWith(fandomIds: ids));
                              }),
                          ],
                        ),
                      const SizedBox(height: 18),
                      _sheetTitle('Creators'),
                      if (creators.isEmpty)
                        Text('No creators for these categories and fandoms yet.',
                            style: AppTheme.inter(size: 12, color: Colors.grey))
                      else
                        for (final cr in creators) _creatorTile(cr, () => draft, update),
                      const SizedBox(height: 18),
                      _sheetTitle('Sort'),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final s in ResourceSort.values)
                            _sheetChip(kResourceSortLabels[s]!, draft.sort == s,
                                (_) => update(draft.copyWith(sort: s))),
                        ],
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => update(ResourceFilter(query: draft.query)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Clear all',
                                style: AppTheme.inter(size: 13, color: Colors.white70)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, draft),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cyan,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Apply',
                                style: AppTheme.inter(
                                    size: 13, color: Colors.black, weight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (applied != null) _c.setFilter(applied.copyWith(query: _c.filter.query));
  }

  Widget _sheetTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: AppTheme.orbitron(size: 10, color: Colors.grey, letterSpacing: 1)),
      );

  Widget _sheetChip(String label, bool selected, ValueChanged<bool> onChanged) =>
      FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onChanged,
        showCheckmark: false,
        labelStyle: AppTheme.inter(
            size: 12,
            weight: FontWeight.w600,
            color: selected ? Colors.black : Colors.white70),
        selectedColor: AppTheme.cyan,
        backgroundColor: AppTheme.bg,
        side: BorderSide(color: selected ? AppTheme.cyan : AppTheme.border),
      );

  Widget _creatorTile(
          Creator c, ResourceFilter Function() current, void Function(ResourceFilter) update) =>
      CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        value: current().creatorIds.contains(c.id),
        activeColor: AppTheme.cyan,
        checkColor: Colors.black,
        onChanged: (on) {
          final ids = {...current().creatorIds};
          (on ?? false) ? ids.add(c.id) : ids.remove(c.id);
          update(current().copyWith(creatorIds: ids));
        },
        secondary: CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
          backgroundImage: c.avatarUrl.isNotEmpty ? NetworkImage(c.avatarUrl) : null,
          onBackgroundImageError: c.avatarUrl.isNotEmpty ? (e, st) {} : null,
          child: c.avatarUrl.isEmpty
              ? Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                  style: AppTheme.inter(size: 12, color: Colors.white))
              : null,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(c.name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(size: 13, color: Colors.white)),
            ),
            if (c.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded, color: AppTheme.cyan, size: 14),
            ],
          ],
        ),
        subtitle: Text(kCreatorKindLabels[c.kind] ?? c.kind,
            style: AppTheme.inter(size: 11, color: Colors.grey)),
      );
}
