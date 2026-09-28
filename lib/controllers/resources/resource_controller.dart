import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../controllers/fandoms/fandom_suggestions.dart';
import '../../logic/resource_query.dart';
import '../../models/creator.dart';
import '../../models/fandom.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/resource_repository.dart';

class ResourceController extends ChangeNotifier {
  final ResourceRepository repository;
  final ResourceFilter? initialFilter;
  final Future<List<String>> Function() _interests;

  ResourceController({
    this.repository = const FirestoreResourceRepository(),
    this.initialFilter,
    Future<List<String>> Function()? interests,
  }) : _interests = interests ?? FandomSuggestions.interestCategories {
    _filter = initialFilter ?? const ResourceFilter();
  }

  static const Duration searchDebounce = Duration(milliseconds: 300);

  ResourceData? _data;
  Object? _error;
  bool _loading = false;
  bool _initialized = false;
  late ResourceFilter _filter;
  Set<String> _userCategoryIds = const {};
  Timer? _debounce;
  bool _disposed = false;

  List<Post> _results = const [];
  List<String> _trendingTags = const [];

  bool get loading => _loading;
  Object? get error => _error;
  bool get hasData => _data != null;
  ResourceData? get data => _data;
  ResourceFilter get filter => _filter;
  Set<String> get userCategoryIds => _userCategoryIds;
  bool get hasInterests => _userCategoryIds.isNotEmpty;
  List<Post> get results => _results;
  List<String> get trendingTags => _trendingTags;
  List<String> get followedFandomIds =>
      AuthService.instance.currentUser?.followedFandomIds ?? const [];
  bool get isSignedIn => AuthService.instance.currentUser != null;

  List<Fandom> get matchingFandoms =>
      _data == null ? const [] : matchFandoms(_data!.fandoms, _filter.query);

  /// Creators with at least one result under the current category and
  /// fandom filters (plus the creators already selected, so they can be
  /// unticked).
  List<Creator> get availableCreators => availableCreatorsFor(_filter);

  List<Creator> availableCreatorsFor(ResourceFilter f) {
    final d = _data;
    if (d == null) return const [];
    final scoped = applyResourceFilter(
      d.posts,
      ResourceFilter(categoryIds: f.categoryIds, fandomIds: f.fandomIds),
      _userCategoryIds,
    );
    final ids = {for (final p in scoped) if (p.hasCreator) p.creatorId};
    return d.creators
        .where((c) => ids.contains(c.id) || f.creatorIds.contains(c.id))
        .toList();
  }

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    _notify();
    try {
      final results = await Future.wait<Object>([
        repository.loadAll(),
        _interests(),
      ]);
      _data = results[0] as ResourceData;
      _userCategoryIds = (results[1] as List<String>).toSet();
      if (!_initialized) {
        _initialized = true;
        if (initialFilter == null && _userCategoryIds.isNotEmpty) {
          _filter = _filter.copyWith(myInterestsOnly: true);
        }
      }
      _recompute();
    } catch (e) {
      debugPrint('Resources load failed: $e');
      _error = e;
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<void> refresh() => load();

  void setQuery(String query) {
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () {
      if (_filter.query == query) return;
      setFilter(_filter.copyWith(query: query));
    });
  }

  void setFilter(ResourceFilter filter) {
    _filter = filter;
    _recompute();
    _notify();
  }

  void setType(String? type) =>
      setFilter(_filter.copyWith(types: type == null ? {} : {type}));

  void toggleTag(String tag) {
    final tags = Set<String>.of(_filter.tags);
    tags.contains(tag) ? tags.remove(tag) : tags.add(tag);
    setFilter(_filter.copyWith(tags: tags));
  }

  void setMyInterests(bool on) =>
      setFilter(_filter.copyWith(myInterestsOnly: on));

  void clearAll() => setFilter(ResourceFilter(query: _filter.query));

  void _recompute() {
    final d = _data;
    if (d == null) return;
    _results = applyResourceFilter(d.posts, _filter, _userCategoryIds);
    _trendingTags =
        computeTrendingTags(d.posts, d.pinnedTagSlugs, DateTime.now());
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
