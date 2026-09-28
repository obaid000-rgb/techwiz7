import '../../models/fandom.dart';
import '../../services/auth_service.dart';
import '../../services/fandom_service.dart';
import '../../services/first_run_service.dart';
import '../../utils/fandom_stats.dart';

enum SuggestionSource { interests, trending, mostFollowed }

class FandomSuggestions {
  final List<Fandom> fandoms;
  final SuggestionSource source;
  const FandomSuggestions(this.fandoms, this.source);

  static Future<List<String>> interestCategories() async {
    final user = AuthService.instance.currentUser;
    if (user != null) return user.categories;
    return (await FirstRunService.instance.readPending())?.categories ??
        const <String>[];
  }

  static Future<FandomSuggestions> load({
    int limit = 10,
    Set<String> exclude = const {},
  }) async {
    List<Fandom> keep(Iterable<Fandom> list) =>
        list.where((f) => !exclude.contains(f.id)).take(limit).toList();

    final categories = await interestCategories();
    final fromInterests = <Fandom>[];
    for (final c in categories) {
      fromInterests.addAll(await FandomService.instance.getByCategory(c));
    }
    if (keep(fromInterests).isNotEmpty) {
      return FandomSuggestions(keep(fromInterests), SuggestionSource.interests);
    }
    final all = await FandomService.instance.getAllActive();
    final trending = rankTrendingFandoms(all, DateTime.now(),
        limit: all.length, fallbackToMostFollowed: false);
    if (keep(trending).isNotEmpty) {
      return FandomSuggestions(keep(trending), SuggestionSource.trending);
    }
    all.sort((a, b) => b.followerCount.compareTo(a.followerCount));
    return FandomSuggestions(keep(all), SuggestionSource.mostFollowed);
  }
}
