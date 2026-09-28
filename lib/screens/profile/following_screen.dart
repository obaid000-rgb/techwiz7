import 'package:flutter/material.dart';
import '../../controllers/fandoms/fandom_suggestions.dart';
import '../../models/fandom.dart';
import '../../services/auth_service.dart';
import '../../services/fandom_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fandom_stats.dart';
import '../../widgets/follow_button.dart';
import '../fandoms/fandom_page_screen.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  // The list is a snapshot taken when the screen opens: unfollowing flips
  // the row's button to "Follow" but keeps the row, so the fan can follow
  // again right away. Reopening the screen shows the fresh list.
  late final List<String> _openedWith = List.of(
      AuthService.instance.currentUser?.followedFandomIds ?? const []);
  late Future<List<Fandom>> _fandoms = _load();
  late Future<FandomSuggestions> _suggestions =
      FandomSuggestions.load(limit: 10, exclude: _openedWith.toSet());
  final _searchCtr = TextEditingController();
  String _query = '';

  Future<List<Fandom>> _load() async {
    if (_openedWith.isEmpty) return const [];
    final found = await FandomService.instance.getByIds(_openedWith);
    final byId = {for (final f in found) f.id: f};
    return [
      for (final id in _openedWith)
        if (byId[id]?.isActive ?? false) byId[id]!,
    ];
  }

  @override
  void initState() {
    super.initState();
    _fandoms;
    _suggestions;
    _searchCtr.addListener(() => setState(() => _query = _searchCtr.text));
  }

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

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
        title: FutureBuilder<List<Fandom>>(
          future: _fandoms,
          builder: (context, snap) => ValueListenableBuilder<UserData?>(
            valueListenable: AuthService.instance.userNotifier,
            builder: (context, user, _) {
              final following = snap.data
                  ?.where((f) => user?.followedFandomIds.contains(f.id) ?? false)
                  .length;
              return Text(
                following == null ? 'Following' : 'Following · $following',
                style: AppTheme.orbitron(size: 13),
              );
            },
          ),
        ),
      ),
      body: FutureBuilder<List<Fandom>>(
        future: _fandoms,
        builder: (context, snap) {
          final children = <Widget>[];
          if (snap.hasError) {
            debugPrint('Following load error: ${snap.error}');
            children.add(_stateBox(Icons.wifi_off, 'Could not load the fandoms you follow',
                'Check your connection and try again.',
                onRetry: () => setState(() => _fandoms = _load())));
          } else if (snap.connectionState != ConnectionState.done) {
            children.add(const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppTheme.cyan)),
            ));
          } else {
            final all = snap.data ?? const <Fandom>[];
            if (all.isEmpty) {
              children.add(_stateBox(Icons.hub_outlined,
                  'You\'re not following any fandoms yet',
                  'Follow a few below to fill your Home feed.'));
            } else {
              children.add(_searchBox());
              final q = _query.trim().toLowerCase();
              final shown = q.isEmpty
                  ? all
                  : all.where((f) => f.name.toLowerCase().contains(q)).toList();
              if (shown.isEmpty) {
                children.add(_stateBox(Icons.search_off,
                    'No fandoms match "${_query.trim()}"', 'Try a different name.'));
              } else {
                for (final f in shown) {
                  children.add(_row(f));
                }
              }
            }
            children.add(_suggestionsSection());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: children,
          );
        },
      ),
    );
  }

  Widget _searchBox() => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: _searchCtr,
          style: AppTheme.inter(size: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search fandoms you follow',
            hintStyle: AppTheme.inter(size: 13, color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                    onPressed: _searchCtr.clear,
                  ),
            filled: true,
            fillColor: AppTheme.card,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      );

  Widget _row(Fandom f) => InkWell(
        key: ValueKey(f.id),
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FandomPageScreen(fandomId: f.id, initial: f)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              FandomLogo(fandom: f, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      [if (f.categoryName.isNotEmpty) f.categoryName, followersLabel(f.followerCount)]
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FollowButton(fandomId: f.id, compact: true),
            ],
          ),
        ),
      );

  Widget _suggestionsSection() => FutureBuilder<FandomSuggestions>(
        future: _suggestions,
        builder: (context, snap) {
          final Widget body;
          if (snap.hasError) {
            debugPrint('Following suggestions error: ${snap.error}');
            body = _stateBox(Icons.wifi_off, 'Could not load suggestions',
                'Check your connection and try again.',
                onRetry: () => setState(() => _suggestions = FandomSuggestions.load(
                    limit: 10, exclude: _openedWith.toSet())));
          } else if (snap.connectionState != ConnectionState.done) {
            body = const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan)),
            );
          } else {
            final list = snap.data?.fandoms ?? const <Fandom>[];
            if (list.isEmpty) return const SizedBox.shrink();
            body = Column(children: [for (final f in list) _row(f)]);
          }
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SUGGESTED FOR YOU',
                    style: AppTheme.orbitron(size: 11, letterSpacing: 1)),
                const SizedBox(height: 6),
                body,
              ],
            ),
          );
        },
      );

  Widget _stateBox(IconData icon, String title, String subtitle,
          {VoidCallback? onRetry}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey, size: 34),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(
                      size: 14, color: Colors.white70, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(size: 12, color: Colors.grey)),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: Text('Try again',
                      style: AppTheme.inter(size: 12, color: AppTheme.cyan)),
                ),
            ],
          ),
        ),
      );
}
