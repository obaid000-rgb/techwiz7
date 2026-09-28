import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../models/avatar_library_item.dart';
import '../../models/avatar_preset.dart';
import '../../services/avatar_library_service.dart';
import '../../services/category_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_view.dart';

class AvatarChoice {
  final String presetId;
  final String imageUrl;
  const AvatarChoice.preset(this.presetId) : imageUrl = '';
  const AvatarChoice.image(this.imageUrl) : presetId = '';
}

class ChooseAvatarScreen extends StatefulWidget {
  final String name;
  const ChooseAvatarScreen({super.key, required this.name});

  @override
  State<ChooseAvatarScreen> createState() => _ChooseAvatarScreenState();
}

class _ChooseAvatarScreenState extends State<ChooseAvatarScreen> {
  late final Stream<List<AppCategory>> _categories = CategoryService.instance.watchActiveCategories();
  late final Stream<List<AvatarLibraryItem>> _library = AvatarLibraryService.instance.watchActive();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCategory>>(
      stream: _categories,
      builder: (context, catSnap) {
        final cats = catSnap.data ?? const <AppCategory>[];
        return DefaultTabController(
          key: ValueKey(cats.map((c) => c.key).join(',')),
          length: cats.length + 1,
          child: Scaffold(
            backgroundColor: AppTheme.bg,
            appBar: AppBar(
              backgroundColor: AppTheme.card,
              title: Text('Choose an avatar', style: AppTheme.orbitron(size: 13)),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppTheme.cyan,
                labelColor: AppTheme.cyan,
                unselectedLabelColor: Colors.grey,
                labelStyle: AppTheme.inter(size: 13, weight: FontWeight.w700),
                tabs: [
                  const Tab(text: 'General'),
                  for (final c in cats) Tab(text: c.name),
                ],
              ),
            ),
            body: StreamBuilder<List<AvatarLibraryItem>>(
              stream: _library,
              builder: (context, libSnap) {
                final library = libSnap.data ?? const <AvatarLibraryItem>[];
                final catKeys = {for (final c in cats) c.key};
                return TabBarView(children: [
                  _grid(
                    [
                      for (final a in library)
                        if (a.categoryId == AvatarLibraryItem.general || !catKeys.contains(a.categoryId)) a,
                    ],
                    presetsForGeneral([for (final c in cats) (key: c.key, name: c.name)]),
                  ),
                  for (final c in cats)
                    _grid(
                      [for (final a in library) if (a.categoryId == c.key) a],
                      presetsForCategory(c.key, c.name),
                    ),
                ]);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _grid(List<AvatarLibraryItem> library, List<AvatarPreset> presets) {
    if (library.isEmpty && presets.isEmpty) {
      return Center(
        child: Text('No avatars here yet.', style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
      );
    }
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        for (final a in library)
          _tile(
            AvatarView(name: widget.name, avatarUrl: a.imageUrl, radius: 34),
            'Library avatar',
            AvatarChoice.image(a.imageUrl),
          ),
        for (final p in presets)
          _tile(
            AvatarView(name: widget.name, avatarPresetId: p.id, radius: 34),
            p.label,
            AvatarChoice.preset(p.id),
          ),
      ],
    );
  }

  Widget _tile(Widget avatar, String label, AvatarChoice choice) => Semantics(
        button: true,
        label: label,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.pop(context, choice),
          child: FittedBox(child: avatar),
        ),
      );
}
