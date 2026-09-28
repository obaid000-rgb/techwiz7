import '../../../models/app_category.dart';
import '../../../models/fandom.dart';
import '../../../services/category_service.dart';
import '../../../services/fandom_service.dart';
import '../../../utils/tag_utils.dart' as tag_utils;

class FandomGroup {
  final String categoryId;
  final String categoryName;
  final List<Fandom> fandoms;
  const FandomGroup(this.categoryId, this.categoryName, this.fandoms);
}

class SeedResult {
  final List<String> created;
  final List<String> alreadyExisted;
  final Map<String, List<String>> skippedCategories;
  const SeedResult(this.created, this.alreadyExisted, this.skippedCategories);
}

class _DemoFandom {
  final String name;
  final String description;
  final List<String> tags;
  const _DemoFandom(this.name, this.description, this.tags);
}

const Map<String, List<_DemoFandom>> _kDemoFandoms = {
  'Anime': [
    _DemoFandom('Naruto', 'A young ninja chases his dream of becoming Hokage.',
        ['shonen', 'ninja', 'action']),
    _DemoFandom('One Piece', 'Luffy and the Straw Hat crew hunt for the legendary One Piece.',
        ['shonen', 'pirates', 'adventure']),
    _DemoFandom('Attack on Titan', 'Humanity fights for survival against man-eating Titans.',
        ['dark fantasy', 'action']),
    _DemoFandom('Demon Slayer', 'Tanjiro trains as a demon slayer to save his sister.',
        ['shonen', 'demons', 'action']),
  ],
  'Gaming': [
    _DemoFandom('Free Fire', 'Fast 10-minute battle royale matches for 50 players.',
        ['battle royale', 'mobile', 'shooter']),
    _DemoFandom('PUBG Mobile', 'The original 100-player battle royale, on your phone.',
        ['battle royale', 'mobile', 'shooter']),
    _DemoFandom('Valorant', 'Tactical 5v5 shooter where agents bring unique abilities.',
        ['tactical shooter', 'esports', 'pc']),
    _DemoFandom('Forza Horizon', 'Open-world racing festival with hundreds of real cars.',
        ['racing', 'open world']),
  ],
  'Movies & TV': [
    _DemoFandom('Marvel Cinematic Universe', 'The connected saga of Marvel heroes on screen.',
        ['superhero', 'action', 'cinematic universe']),
    _DemoFandom('Star Wars', 'A galaxy far, far away of Jedi, Sith and rebels.',
        ['sci-fi', 'space opera']),
    _DemoFandom('Harry Potter', 'The boy who lived and the wizarding world of Hogwarts.',
        ['fantasy', 'magic']),
  ],
  'Comics': [
    _DemoFandom('DC Comics', 'Batman, Superman, Wonder Woman and the Justice League.',
        ['superhero', 'comics']),
    _DemoFandom('Spider-Man', 'Peter Parker balances everyday life with being Spider-Man.',
        ['superhero', 'comics', 'marvel']),
  ],
  'K-Pop': [
    _DemoFandom('BTS', 'The global K-pop group behind "Dynamite" and "Butter".',
        ['k-pop', 'boy group', 'music']),
    _DemoFandom('BLACKPINK', 'The record-breaking K-pop girl group.',
        ['k-pop', 'girl group', 'music']),
  ],
};

class FandomController {
  const FandomController();

  List<String> normalizeTags(Iterable<String> raw) =>
      tag_utils.normalizeTags(raw);

  List<FandomGroup> group(
    List<Fandom> fandoms,
    List<AppCategory> categories, {
    String? categoryId,
    String query = '',
  }) {
    final q = query.trim().toLowerCase();
    final visible = fandoms.where((f) =>
        (categoryId == null || f.categoryId == categoryId) &&
        (q.isEmpty || f.name.toLowerCase().contains(q)));

    final byCategory = <String, List<Fandom>>{};
    for (final f in visible) {
      byCategory.putIfAbsent(f.categoryId, () => []).add(f);
    }

    final sortedCats = List<AppCategory>.from(categories)
      ..sort((a, b) => a.order.compareTo(b.order));
    final groups = <FandomGroup>[];
    for (final c in sortedCats) {
      final list = byCategory.remove(c.key);
      if (list != null) groups.add(FandomGroup(c.key, c.name, list));
    }
    for (final entry in byCategory.entries) {
      final name = entry.value.first.categoryName;
      groups.add(FandomGroup(
          entry.key, name.isEmpty ? 'No category' : name, entry.value));
    }
    return groups;
  }

  Future<SeedResult> seedDemoFandoms() async {
    final categories = await CategoryService.instance.fetchCategories();
    final existing = await FandomService.instance.getAll();
    final existingIds = existing.map((f) => f.id).toSet();
    final existingNames =
        existing.map((f) => f.name.trim().toLowerCase()).toSet();

    final created = <String>[];
    final alreadyExisted = <String>[];
    final skipped = <String, List<String>>{};

    for (final entry in _kDemoFandoms.entries) {
      final matches = categories.where(
          (c) => c.name.trim().toLowerCase() == entry.key.toLowerCase());
      if (matches.isEmpty) {
        skipped[entry.key] = entry.value.map((d) => d.name).toList();
        continue;
      }
      final category = matches.first;
      for (final demo in entry.value) {
        final id = Fandom.slugFor(demo.name);
        if (existingIds.contains(id) ||
            existingNames.contains(demo.name.toLowerCase())) {
          alreadyExisted.add(demo.name);
          continue;
        }
        final added = await FandomService.instance.createIfAbsent(Fandom(
          id: id,
          categoryId: category.key,
          categoryName: category.name,
          name: demo.name,
          description: demo.description,
          tags: normalizeTags(demo.tags),
          createdAt: DateTime.now(),
        ));
        (added ? created : alreadyExisted).add(demo.name);
      }
    }
    return SeedResult(created, alreadyExisted, skipped);
  }
}
