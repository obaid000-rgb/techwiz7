import 'dart:math' as math;

import '../models/creator.dart';
import '../models/fandom.dart';
import '../models/post.dart';

enum ResourceSort { newest, mostViewed, trending }

const Map<ResourceSort, String> kResourceSortLabels = {
  ResourceSort.newest: 'Newest',
  ResourceSort.mostViewed: 'Most viewed',
  ResourceSort.trending: 'Trending',
};

class ResourceFilter {
  final String query;
  final Set<String> types;
  final Set<String> categoryIds;
  final Set<String> fandomIds;
  final Set<String> creatorIds;
  final ResourceSort sort;
  final bool myInterestsOnly;

  const ResourceFilter({
    this.query = '',
    this.types = const {},
    this.categoryIds = const {},
    this.fandomIds = const {},
    this.creatorIds = const {},
    this.sort = ResourceSort.newest,
    this.myInterestsOnly = false,
  });

  ResourceFilter copyWith({
    String? query,
    Set<String>? types,
    Set<String>? categoryIds,
    Set<String>? fandomIds,
    Set<String>? creatorIds,
    ResourceSort? sort,
    bool? myInterestsOnly,
  }) =>
      ResourceFilter(
        query: query ?? this.query,
        types: types ?? this.types,
        categoryIds: categoryIds ?? this.categoryIds,
        fandomIds: fandomIds ?? this.fandomIds,
        creatorIds: creatorIds ?? this.creatorIds,
        sort: sort ?? this.sort,
        myInterestsOnly: myInterestsOnly ?? this.myInterestsOnly,
      );

  /// No query and nothing narrowing or re-ordering the results.
  bool get isEmpty => query.trim().isEmpty && activeCount == 0;

  /// Number of active constraints, one per selected value (the filter
  /// badge and the active-chip row show exactly these). The query is not
  /// counted: it lives in the search bar.
  int get activeCount =>
      types.length +
      categoryIds.length +
      fandomIds.length +
      creatorIds.length +
      (myInterestsOnly ? 1 : 0) +
      (sort != ResourceSort.newest ? 1 : 0);
}

String normalizeText(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

List<String> _words(String s) => normalizeText(s)
    .split(RegExp(r'[^a-z0-9]+'))
    .where((w) => w.isNotEmpty)
    .toList();

List<String> queryWords(String query) => _words(query);

bool _anyPrefix(List<String> fieldWords, String q) =>
    fieldWords.any((w) => w.startsWith(q));

// Keyword search scoring. The query and every field are lowercased with
// spaces collapsed, then split into words. A query word matches a field
// when any word of that field STARTS WITH it ("nar" matches "Naruto").
// Every query word must match at least one field (AND across words), or
// the post is excluded (null). For each query word the post earns:
//   title 3 + fandomName or creatorName 2 + body 1,
// and the per-word scores are summed. So a title hit on every word
// outranks posts that only mention the words in their body.
int? searchScore(Post p, List<String> words) {
  if (words.isEmpty) return 0;
  final title = _words(p.title);
  final names = [..._words(p.fandomName), ..._words(p.creatorName)];
  final body = _words(p.content);
  var score = 0;
  for (final q in words) {
    var word = 0;
    if (_anyPrefix(title, q)) word += 3;
    if (_anyPrefix(names, q)) word += 2;
    if (_anyPrefix(body, q)) word += 1;
    if (word == 0) return null;
    score += word;
  }
  return score;
}

// Trending weight of one post: popularity damped by a logarithm so a few
// viral posts don't swamp everything, times a half-life decay of 7 days:
//   (1 + ln(1 + viewCount)) × 0.5^(ageDays / 7)
// A brand-new post with no views weighs 1; each week of age halves the
// weight. With equal views, the newer post always outranks the older one.
double trendingWeight(Post p, DateTime now) {
  final ageDays =
      math.max(0, now.difference(p.createdAt).inMinutes) / (60 * 24);
  return (1 + math.log(1 + math.max(0, p.viewCount))) *
      math.pow(0.5, ageDays / 7).toDouble();
}

List<Post> applyResourceFilter(
  List<Post> posts,
  ResourceFilter filter,
  Set<String> userCategoryIds, {
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final words = queryWords(filter.query);
  final scores = <String, int>{};
  final out = <Post>[];
  for (final p in posts) {
    if (!p.isActive) continue;
    if (filter.types.isNotEmpty && !filter.types.contains(p.contentType)) {
      continue;
    }
    if (filter.categoryIds.isNotEmpty &&
        !filter.categoryIds.contains(p.category)) {
      continue;
    }
    if (filter.fandomIds.isNotEmpty && !filter.fandomIds.contains(p.fandomId)) {
      continue;
    }
    if (filter.creatorIds.isNotEmpty &&
        !filter.creatorIds.contains(p.creatorId)) {
      continue;
    }
    if (filter.myInterestsOnly && !userCategoryIds.contains(p.category)) {
      continue;
    }
    if (words.isNotEmpty) {
      final s = searchScore(p, words);
      if (s == null) continue;
      scores[p.id] = s;
    }
    out.add(p);
  }

  int newest(Post a, Post b) => b.createdAt.compareTo(a.createdAt);
  if (words.isNotEmpty) {
    out.sort((a, b) {
      final byScore = scores[b.id]!.compareTo(scores[a.id]!);
      return byScore != 0 ? byScore : newest(a, b);
    });
  } else {
    switch (filter.sort) {
      case ResourceSort.newest:
        out.sort(newest);
      case ResourceSort.mostViewed:
        out.sort((a, b) {
          final byViews = b.viewCount.compareTo(a.viewCount);
          return byViews != 0 ? byViews : newest(a, b);
        });
      case ResourceSort.trending:
        final w = {for (final p in out) p.id: trendingWeight(p, at)};
        out.sort((a, b) {
          final byWeight = w[b.id]!.compareTo(w[a.id]!);
          return byWeight != 0 ? byWeight : newest(a, b);
        });
    }
  }
  return out;
}

/// Fandoms whose name or tags match any query word (prefix match), best
/// match (most query words) first. Any-word so "naruto trailer" still
/// surfaces Naruto even though "trailer" is not part of its name.
List<Fandom> matchFandoms(List<Fandom> fandoms, String query) {
  final words = queryWords(query);
  if (words.isEmpty) return const [];
  final hits = <Fandom, int>{};
  for (final f in fandoms) {
    final fieldWords = [
      ..._words(f.name),
      for (final t in f.tags) ..._words(t),
    ];
    final n = words.where((q) => _anyPrefix(fieldWords, q)).length;
    if (n > 0) hits[f] = n;
  }
  return hits.keys.toList()..sort((a, b) => hits[b]!.compareTo(hits[a]!));
}

/// Active creators whose name matches a query word (prefix match, any
/// word), best match first, for the "Creators" row above search results.
List<Creator> matchCreators(List<Creator> creators, String query) {
  final words = queryWords(query);
  if (words.isEmpty) return const [];
  final hits = <Creator, int>{};
  for (final c in creators) {
    if (!c.isActive) continue;
    final n = words.where((q) => _anyPrefix(_words(c.name), q)).length;
    if (n > 0) hits[c] = n;
  }
  return hits.keys.toList()..sort((a, b) => hits[b]!.compareTo(hits[a]!));
}
