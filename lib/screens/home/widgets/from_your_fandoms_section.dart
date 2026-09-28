import 'dart:async';

import 'package:flutter/material.dart';
import '../../../models/fandom.dart';
import '../../../models/post.dart';
import '../../../services/auth_service.dart';
import '../../../services/fandom_service.dart';
import '../../../controllers/fandoms/fandom_suggestions.dart';
import '../../../services/post_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/fandom_stats.dart';
import '../../../widgets/follow_button.dart';
import '../../../widgets/lore_card.dart';
import '../../fandoms/fandom_page_screen.dart';

class FromYourFandomsSection extends StatefulWidget {
  const FromYourFandomsSection({super.key});

  static String headerFor(List<String> names) {
    if (names.isEmpty) return 'From your fandoms';
    if (names.length == 1) return 'From ${names.first}';
    if (names.length == 2) return 'From ${names[0]} and ${names[1]}';
    if (names.length == 3) return 'From ${names[0]}, ${names[1]} and ${names[2]}';
    return 'From ${names[0]}, ${names[1]} and ${names.length - 2} more';
  }

  @override
  State<FromYourFandomsSection> createState() => _FromYourFandomsSectionState();
}

class _FromYourFandomsSectionState extends State<FromYourFandomsSection> {
  String? _feedKey;
  StreamSubscription<List<Post>>? _postSub;
  StreamSubscription<List<Fandom>>? _fandomSub;
  List<Post>? _posts;
  Object? _postsError;
  List<Fandom>? _followed;

  String? _suggestKey;
  List<Fandom>? _suggestions;
  SuggestionSource _suggestionSource = SuggestionSource.interests;
  Object? _suggestError;

  @override
  void initState() {
    super.initState();
    AuthService.instance.userNotifier.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    AuthService.instance.userNotifier.removeListener(_sync);
    _postSub?.cancel();
    _fandomSub?.cancel();
    super.dispose();
  }

  List<String> get _followedIds =>
      AuthService.instance.currentUser?.followedFandomIds ?? const [];

  void _sync() {
    final ids = _followedIds;
    final key = ids.isEmpty ? null : ([...ids]..sort()).join(',');
    if (key != _feedKey) {
      _feedKey = key;
      _postSub?.cancel();
      _postSub = null;
      _fandomSub?.cancel();
      _fandomSub = null;
      setState(() {
        _posts = null;
        _postsError = null;
        _followed = null;
      });
      if (key != null) _startFeed(ids);
    }
    _loadSuggestions();
  }

  void _startFeed(List<String> ids) {
    final query = ids.take(FandomService.maxFollowed).toList();
    _postSub = PostService.instance.watchPostsInFandoms(query).listen(
      (posts) {
        if (mounted) setState(() => _posts = posts);
      },
      onError: (Object e) {
        debugPrint('From your fandoms load error: $e');
        if (mounted) setState(() => _postsError = e);
      },
    );
    _fandomSub = FandomService.instance.watchByIds(query).listen(
      (list) {
        if (mounted) setState(() => _followed = list);
      },
      onError: (Object e) {
        debugPrint('Followed fandoms load error: $e');
        if (mounted) setState(() => _postsError = e);
      },
    );
  }

  Future<void> _loadSuggestions() async {
    final user = AuthService.instance.currentUser;
    final categories = await FandomSuggestions.interestCategories();
    final key = '${user?.uid ?? 'guest'}|${categories.join(',')}';
    if (key == _suggestKey || !mounted) return;
    _suggestKey = key;
    setState(() {
      _suggestions = null;
      _suggestError = null;
    });
    try {
      final result = await FandomSuggestions.load();
      if (!mounted || key != _suggestKey) return;
      setState(() {
        _suggestions = result.fandoms;
        _suggestionSource = result.source;
      });
    } catch (e) {
      debugPrint('Suggested fandoms load error: $e');
      if (mounted && key == _suggestKey) setState(() => _suggestError = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ids = _followedIds;
    if (ids.isNotEmpty) {
      final followed = _followed;
      final activeFollowed = followed == null
          ? null
          : [
              for (final id in ids)
                ...followed.where((f) => f.id == id && f.isActive),
            ];
      if (activeFollowed == null || activeFollowed.isNotEmpty) {
        return _feed(activeFollowed);
      }
    }
    return _suggestionsView();
  }

  Widget _feed(List<Fandom>? activeFollowed) {
    final Widget body;
    if (_postsError != null) {
      body = _message(Icons.wifi_off, 'Could not load your fandoms',
          'Check your connection and try again.');
    } else if (_posts == null || activeFollowed == null) {
      body = _loading();
    } else {
      final activeIds = {for (final f in activeFollowed) f.id};
      final posts = _posts!
          .where((p) => p.isActive && activeIds.contains(p.fandomId))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final shown = posts.take(10).toList();
      body = shown.isEmpty
          ? _message(Icons.auto_stories_outlined, 'No posts yet',
              'New posts from the fandoms you follow will show up here.')
          : SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: shown.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => SizedBox(
                    width: 270,
                    child: LoreCard(key: ValueKey(shown[i].id), post: shown[i])),
              ),
            );
    }
    final names = [for (final f in activeFollowed ?? const <Fandom>[]) f.name];
    return _section('FROM YOUR FANDOMS', FromYourFandomsSection.headerFor(names), body);
  }

  Widget _suggestionsView() {
    final Widget body;
    final list = _suggestions;
    if (_suggestError != null) {
      body = _message(Icons.wifi_off, 'Could not load suggestions',
          'Check your connection and try again.');
    } else if (list == null) {
      body = _loading();
    } else if (list.isEmpty) {
      body = _message(Icons.hub_outlined, 'No fandoms to suggest yet',
          'New fandoms will appear here soon.');
    } else {
      body = SizedBox(
        height: 164,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) => _suggestionCard(list[i]),
        ),
      );
    }
    return _section(
      'SUGGESTED FANDOMS FOR YOU',
      switch (_suggestionSource) {
        SuggestionSource.interests => 'Based on the categories you picked',
        SuggestionSource.trending => 'Trending fandoms to follow',
        SuggestionSource.mostFollowed => 'Popular fandoms to follow',
      },
      body,
    );
  }

  Widget _suggestionCard(Fandom f) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FandomPageScreen(fandomId: f.id, initial: f)),
        ),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FandomLogo(fandom: f, size: 36),
              const SizedBox(height: 8),
              Text(f.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.orbitron(size: 11, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(f.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(size: 10, color: Colors.grey)),
              Text(followersLabel(f.followerCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(size: 10, color: AppTheme.cyan)),
              const Spacer(),
              FollowButton(fandomId: f.id, compact: true),
            ],
          ),
        ),
      );

  Widget _section(String title, String subtitle, Widget body) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.orbitron(size: 13, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          body,
          const SizedBox(height: 28),
        ],
      );

  Widget _loading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
        ),
      );

  Widget _message(IconData icon, String title, String subtitle) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTheme.inter(
                    size: 13, color: Colors.white70, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.inter(size: 12, color: Colors.grey)),
          ],
        ),
      );
}
