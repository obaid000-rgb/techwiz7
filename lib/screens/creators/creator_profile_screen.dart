import 'package:flutter/material.dart';
import '../../logic/resource_query.dart';
import '../../models/creator.dart';
import '../../models/fandom.dart';
import '../../models/post.dart';
import '../../services/creator_service.dart';
import '../../services/fandom_service.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fandom_stats.dart';
import '../../widgets/creator_widgets.dart';
import '../../widgets/lore_card.dart';
import '../fandoms/fandom_page_screen.dart';
import '../resources/resources_screen.dart';

/// A creator's public profile: header, stats, fandoms and their posts.
class CreatorProfileScreen extends StatefulWidget {
  final String creatorId;
  const CreatorProfileScreen({super.key, required this.creatorId});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  late final Stream<Creator?> _creator = CreatorService.instance.watchById(widget.creatorId);
  late final Stream<List<Post>> _posts = PostService.instance.watchPostsByCreator(widget.creatorId);
  Future<List<Fandom>>? _fandoms;
  List<String> _fandomIdsLoaded = const [];
  String _tab = 'All';

  static const _types = ['News', 'Gallery', 'Video', 'Podcast'];

  Future<List<Fandom>> _fandomsFor(Creator c) {
    if (_fandoms == null || _fandomIdsLoaded.join(',') != c.fandomIds.join(',')) {
      _fandomIdsLoaded = List.of(c.fandomIds);
      _fandoms = c.fandomIds.isEmpty
          ? Future.value(const <Fandom>[])
          : FandomService.instance
              .getByIds(c.fandomIds)
              .then((l) => l.where((f) => f.isActive).toList());
    }
    return _fandoms!;
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
        title: Text('Creator', style: AppTheme.orbitron(size: 13)),
      ),
      body: StreamBuilder<Creator?>(
        stream: _creator,
        builder: (context, cSnap) {
          if (cSnap.hasError && !cSnap.hasData) {
            return _state(Icons.wifi_off_rounded, 'Could not load this creator', 'Check your connection and try again.');
          }
          if (cSnap.connectionState == ConnectionState.waiting && !cSnap.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan));
          }
          final c = cSnap.data;
          if (c == null || !c.isActive) {
            return _state(Icons.person_off_outlined, "This creator isn't available",
                'They may have been removed. Go back to keep exploring.');
          }
          return StreamBuilder<List<Post>>(
            stream: _posts,
            builder: (context, pSnap) {
              final posts = pSnap.data;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  _header(c),
                  const SizedBox(height: 16),
                  _stats(c, posts),
                  const SizedBox(height: 16),
                  _fandomChips(c),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResourcesScreen(initialFilter: ResourceFilter(creatorIds: {c.id})),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.cyan),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.travel_explore, size: 18, color: AppTheme.cyan),
                      label: Text('See all in Resources',
                          style: AppTheme.inter(size: 13, weight: FontWeight.w600, color: AppTheme.cyan)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._postsSection(c, pSnap),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _header(Creator c) => Column(children: [
        CreatorAvatar(creator: c, radius: 44),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(
            child: Text(c.name,
                textAlign: TextAlign.center,
                style: AppTheme.orbitron(size: 18, weight: FontWeight.w800)),
          ),
          if (c.isVerified) ...[const SizedBox(width: 6), const VerifiedBadge(size: 18)],
        ]),
        const SizedBox(height: 4),
        Text(creatorKindLabel(c), style: AppTheme.inter(size: 13, color: AppTheme.pink, weight: FontWeight.w600)),
        if (c.bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(c.bio,
              textAlign: TextAlign.center,
              style: AppTheme.inter(size: 13, color: AppTheme.textSecondary, height: 1.5)),
        ],
      ]);

  Widget _stats(Creator c, List<Post>? posts) {
    final views = posts?.fold<int>(0, (sum, p) => sum + p.viewCount) ?? 0;
    Widget stat(String value, String label) => Expanded(
          child: Column(children: [
            Text(value, style: AppTheme.orbitron(size: 17, color: AppTheme.cyan, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
          ]),
        );
    Widget divider() => Container(width: 1, height: 30, color: AppTheme.border);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        stat(posts == null ? '–' : formatCount(posts.length), 'Posts'),
        divider(),
        stat(posts == null ? '–' : formatCount(views), 'Views'),
        divider(),
        stat(formatCount(c.fandomIds.length), 'Fandoms'),
      ]),
    );
  }

  Widget _fandomChips(Creator c) => FutureBuilder<List<Fandom>>(
        future: _fandomsFor(c),
        builder: (context, snap) {
          final fandoms = snap.data ?? const <Fandom>[];
          if (fandoms.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final f in fandoms) FandomLinkChip(fandomId: f.id, label: f.name),
            ]),
          );
        },
      );

  List<Widget> _postsSection(Creator c, AsyncSnapshot<List<Post>> snap) {
    if (snap.hasError && !snap.hasData) {
      return [_state(Icons.wifi_off_rounded, 'Could not load posts', 'Check your connection and try again.')];
    }
    final posts = snap.data;
    if (posts == null) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan)),
        ),
      ];
    }
    if (posts.isEmpty) {
      return [_state(Icons.edit_note_rounded, "${c.name} hasn't posted yet.", '')];
    }
    // Tabs: All, then each type that has at least one post.
    final tabs = ['All', for (final t in _types) if (posts.any((p) => p.contentType == t)) t];
    final tab = tabs.contains(_tab) ? _tab : 'All';
    final shown = tab == 'All' ? posts : posts.where((p) => p.contentType == tab).toList();
    return [
      SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final t in tabs)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(t == 'All' ? 'All (${posts.length})' : t),
                  selected: t == tab,
                  onSelected: (_) => setState(() => _tab = t),
                  showCheckmark: false,
                  selectedColor: AppTheme.accent,
                  backgroundColor: AppTheme.card,
                  labelStyle: AppTheme.inter(size: 12, weight: FontWeight.w600, color: Colors.white),
                  side: BorderSide(color: t == tab ? AppTheme.accent : AppTheme.border),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      for (final p in shown) LoreCard(key: ValueKey(p.id), post: p),
    ];
  }

  Widget _state(IconData icon, String title, String subtitle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppTheme.textMuted, size: 36),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center, style: AppTheme.inter(size: 15, weight: FontWeight.w600)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center, style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
          ],
        ]),
      );
}
