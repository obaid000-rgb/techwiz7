import 'package:flutter/material.dart';
import '../../../logic/event_query.dart';
import '../../../models/event_type.dart';
import '../../../theme/app_theme.dart';

/// Events tab toolbar: search box, type chips (All + each type) and a
/// Filter button whose badge counts the filters set in the sheet.
class EventFilterBar extends StatelessWidget {
  final EventFilter filter;
  final TextEditingController searchController;
  final List<String> cities;
  final bool hasLocation;
  final bool signedIn;
  final ValueChanged<EventFilter> onChanged;
  final VoidCallback onClearAll;

  const EventFilterBar({
    super.key,
    required this.filter,
    required this.searchController,
    required this.cities,
    required this.hasLocation,
    required this.signedIn,
    required this.onChanged,
    required this.onClearAll,
  });

  void _toggleType(EventType t) {
    final types = {...filter.types};
    if (!types.remove(t.key)) types.add(t.key);
    onChanged(filter.copyWith(types: types));
  }

  @override
  Widget build(BuildContext context) {
    final badge = filter.sheetCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (v) => onChanged(filter.copyWith(query: v)),
              textInputAction: TextInputAction.search,
              style: AppTheme.inter(size: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search events, venues, cities',
                hintStyle: AppTheme.inter(size: 13, color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                suffixIcon: filter.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                        onPressed: () {
                          searchController.clear();
                          onChanged(filter.copyWith(query: ''));
                        },
                      ),
                isDense: true,
                filled: true,
                fillColor: AppTheme.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: badge > 0,
            label: Text('$badge'),
            backgroundColor: AppTheme.pink,
            child: OutlinedButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppTheme.card,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => EventFilterSheet(
                  initial: filter,
                  cities: cities,
                  hasLocation: hasLocation,
                  signedIn: signedIn,
                  onChanged: onChanged,
                  onClearAll: onClearAll,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: badge > 0 ? AppTheme.cyan : AppTheme.border),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.tune, size: 18, color: badge > 0 ? AppTheme.cyan : Colors.white70),
              label: Text('Filter',
                  style: AppTheme.inter(
                      size: 13,
                      weight: FontWeight.w600,
                      color: badge > 0 ? AppTheme.cyan : Colors.white70)),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip(
              label: 'All',
              selected: filter.types.isEmpty,
              color: AppTheme.cyan,
              onTap: () => onChanged(filter.copyWith(types: const {})),
            ),
            for (final t in EventType.values)
              _chip(
                label: t == EventType.other ? 'Other' : t.label,
                icon: t.icon,
                color: t.color,
                selected: filter.types.contains(t.key),
                onTap: () => _toggleType(t),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) =>
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(label),
          avatar: icon == null ? null : Icon(icon, size: 15, color: selected ? Colors.black : color),
          showCheckmark: false,
          selected: selected,
          onSelected: (_) => onTap(),
          labelStyle: AppTheme.inter(
              size: 12, weight: FontWeight.w600, color: selected ? Colors.black : Colors.white70),
          backgroundColor: AppTheme.card,
          selectedColor: color,
          side: BorderSide(color: selected ? color : AppTheme.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
}

/// The Filter sheet: date range, radius, city, "My fandoms" and Clear all.
/// Every change applies straight away (the list behind updates live).
class EventFilterSheet extends StatefulWidget {
  final EventFilter initial;
  final List<String> cities;
  final bool hasLocation;
  final bool signedIn;
  final ValueChanged<EventFilter> onChanged;
  final VoidCallback onClearAll;

  const EventFilterSheet({
    super.key,
    required this.initial,
    required this.cities,
    required this.hasLocation,
    required this.signedIn,
    required this.onChanged,
    required this.onClearAll,
  });

  @override
  State<EventFilterSheet> createState() => _EventFilterSheetState();
}

class _EventFilterSheetState extends State<EventFilterSheet> {
  late EventFilter _f = widget.initial;
  String _cityQuery = '';

  void _set(EventFilter f) {
    setState(() => _f = f);
    widget.onChanged(f);
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text, style: AppTheme.orbitron(size: 11, weight: FontWeight.w700, color: AppTheme.textSecondary)),
      );

  Widget _choice(String label, bool selected, VoidCallback? onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onTap == null ? null : (_) => onTap(),
        showCheckmark: false,
        labelStyle: AppTheme.inter(
            size: 12,
            weight: FontWeight.w600,
            color: onTap == null ? AppTheme.textMuted : (selected ? Colors.black : Colors.white70)),
        backgroundColor: AppTheme.bg,
        selectedColor: AppTheme.cyan,
        disabledColor: AppTheme.bg,
        side: BorderSide(color: selected ? AppTheme.cyan : AppTheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );

  @override
  Widget build(BuildContext context) {
    final q = _cityQuery.trim().toLowerCase();
    final shownCities = widget.cities.where((c) => c.toLowerCase().contains(q)).toList();
    bool cityOn(String c) => _f.cities.any((x) => x.toLowerCase() == c.toLowerCase());
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(child: Text('Filters', style: AppTheme.orbitron(size: 15, weight: FontWeight.w700))),
                TextButton(
                  onPressed: () {
                    widget.onClearAll();
                    Navigator.pop(context);
                  },
                  child: Text('Clear all',
                      style: AppTheme.inter(size: 13, weight: FontWeight.w600, color: AppTheme.pink)),
                ),
              ]),
              _heading('DATE'),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final r in EventDateRange.values)
                  _choice(r.label, _f.dateRange == r, () => _set(_f.copyWith(dateRange: r))),
              ]),
              _heading('DISTANCE'),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _choice('Any distance', _f.radiusKm == null || !widget.hasLocation,
                    widget.hasLocation ? () => _set(_f.copyWith(clearRadius: true)) : null),
                for (final km in kEventRadiusOptions)
                  _choice('Within $km km', widget.hasLocation && _f.radiusKm == km,
                      widget.hasLocation ? () => _set(_f.copyWith(radiusKm: km)) : null),
              ]),
              if (!widget.hasLocation)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Icon(Icons.location_off_outlined, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text('Turn on location to filter by distance',
                        style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                  ]),
                ),
              _heading('CITY'),
              if (widget.cities.isEmpty)
                Text('No cities yet.', style: AppTheme.inter(size: 12, color: AppTheme.textMuted))
              else ...[
                if (widget.cities.length > 8)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      onChanged: (v) => setState(() => _cityQuery = v),
                      style: AppTheme.inter(size: 13, color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search cities',
                        isDense: true,
                        prefixIcon: Icon(Icons.search, size: 18),
                      ),
                    ),
                  ),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final c in shownCities)
                    _choice(c, cityOn(c), () {
                      final next = {
                        for (final x in _f.cities)
                          if (x.toLowerCase() != c.toLowerCase()) x,
                      };
                      if (!cityOn(c)) next.add(c);
                      _set(_f.copyWith(cities: next));
                    }),
                ]),
              ],
              if (widget.signedIn) ...[
                _heading('FANDOMS'),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _f.myFandomsOnly,
                    activeThumbColor: AppTheme.cyan,
                    onChanged: (v) => _set(_f.copyWith(myFandomsOnly: v)),
                    title: Text('My fandoms', style: AppTheme.inter(size: 14, weight: FontWeight.w600)),
                    subtitle: Text('Only events linked to fandoms you follow',
                        style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('SHOW EVENTS',
                      style: AppTheme.orbitron(size: 12, color: Colors.white, weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Human labels for the active filters, for the "no matches" message.
List<String> describeEventFilter(EventFilter f) => [
      if (f.query.trim().isNotEmpty) '"${f.query.trim()}"',
      if (f.types.isNotEmpty)
        f.types.map((k) {
          final t = EventType.fromKey(k);
          return t == EventType.other ? 'Other' : t.label;
        }).join(' or '),
      if (f.dateRange != EventDateRange.all) f.dateRange.label,
      if (f.radiusKm != null) 'Within ${f.radiusKm} km',
      if (f.cities.isNotEmpty) f.cities.join(' or '),
      if (f.myFandomsOnly) 'My fandoms',
    ];
