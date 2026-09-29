import '../../models/fandom.dart';
import '../../models/post.dart';
import '../../utils/levels.dart';
import '../../utils/tag_utils.dart';

class FandomTab {
  final String key;
  final String label;
  final List<Post> posts;
  const FandomTab(this.key, this.label, this.posts);
}

class FandomPageController {
  const FandomPageController();

  List<Post> visiblePosts(List<Post> posts) =>
      posts.where((p) => p.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Tabs are filtered on the device from the single fandomId query result:
  // "All" always shows; every other tab is kept only if at least one post
  // matches it, so a tab is never empty. Beginner/Deep Dive come from
  // contentDepth, the rest from contentType.
  List<FandomTab> tabsFor(List<Post> posts) {
    final candidates = [
      FandomTab('all', 'All', posts),
      FandomTab('beginner', 'Beginner',
          posts.where((p) => p.contentDepth == 'beginner').toList()),
      FandomTab('deep', 'Deep Dive',
          posts.where(isDeepDive).toList()),
      for (final type in kPostContentTypes)
        FandomTab(type, type,
            posts.where((p) => p.contentType == type).toList()),
    ];
    return candidates
        .where((t) => t.key == 'all' || t.posts.isNotEmpty)
        .toList();
  }

  List<Fandom> search(List<Fandom> fandoms, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return fandoms;
    final tagQuery = normalizeTag(q);
    return fandoms
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            (tagQuery.isNotEmpty &&
                f.tags.any((t) => normalizeTag(t).contains(tagQuery))))
        .toList();
  }
}
