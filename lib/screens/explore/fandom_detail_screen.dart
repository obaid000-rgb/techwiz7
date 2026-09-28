import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../controllers/beginner_hub/beginner_hub_controller.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/xp_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/levels.dart';
import '../../utils/youtube_utils.dart';
import '../../widgets/category_name.dart';
import '../../widgets/clip_player.dart';
import '../../widgets/creator_widgets.dart';
import '../shop/shop_tab.dart' show showGuestLoginSheet;
import '../fandoms/fandom_page_screen.dart';
import 'video_player_screen.dart';

class FandomDetailScreen extends StatefulWidget {
  final Post post;

  const FandomDetailScreen({super.key, required this.post});

  @override
  State<FandomDetailScreen> createState() => _FandomDetailScreenState();
}

class _FandomDetailScreenState extends State<FandomDetailScreen> {
  YoutubePlayerController? _controller;
  bool _videoError = false;

  late final bool _locked;

  @override
  void initState() {
    super.initState();
    final viewer = AuthService.instance.currentUser;
    _locked = widget.post.contentDepth == 'deep' &&
        !canOpenDeepDive(
            signedIn: viewer != null, isAdmin: viewer?.isAdmin ?? false, xp: viewer?.xp ?? 0);
    // Locked Deep Dive: nothing below loads — no body, media, video, view
    // count or XP. Only the title and cover are shown.
    if (_locked) {
      // Re-check when the viewer logs in from the lock view (or gains XP):
      // once the post is unlocked, reopen it fresh so everything loads.
      AuthService.instance.userNotifier.addListener(_onUserChanged);
      return;
    }
    XpService.instance.award(XpAction.firstPostOpen, targetId: widget.post.id);
    // Trending Today: count this view (signed-in fans only — the security
    // rules only let signed-in users touch the view fields). Fire-and-forget;
    // a failed count must never affect reading the post.
    if (AuthService.instance.isLoggedIn) {
      PostService.instance.recordView(widget.post.id).catchError((Object e) {
        if (kDebugMode) debugPrint('[Trending] recordView failed: $e');
      });
    }
    if (widget.post.contentDepth == 'beginner') BeginnerHubController.markBeginnerGuideRead();
    final post = widget.post;
    if (post.hasVideo) {
      final videoId = extractYoutubeVideoId(post.youtubeUrl!);
      if (videoId == null) {
        _videoError = true;
      } else {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: true,
        )..stream.listen((value) {
            if (value.hasError && mounted) {
              setState(() => _videoError = true);
            }
          });
      }
    }
  }

  bool _reopened = false;

  void _onUserChanged() {
    if (!mounted || _reopened) return;
    final viewer = AuthService.instance.currentUser;
    if (viewer == null) return;
    if (!canOpenDeepDive(signedIn: true, isAdmin: viewer.isAdmin, xp: viewer.xp)) return;
    _reopened = true;
    AuthService.instance.userNotifier.removeListener(_onUserChanged);
    // Swap this route specifically (the login sheet/screen may still be on
    // top of it), after the current frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      final newRoute = MaterialPageRoute<void>(
          builder: (_) => FandomDetailScreen(post: widget.post));
      if (route != null) {
        Navigator.of(context).replace(oldRoute: route, newRoute: newRoute);
      } else {
        Navigator.of(context).pushReplacement(newRoute);
      }
    });
  }

  @override
  void dispose() {
    AuthService.instance.userNotifier.removeListener(_onUserChanged);
    _controller?.close();
    super.dispose();
  }

  Widget _lockedView(Post post) {
    final viewer = AuthService.instance.currentUser;
    final videoId = post.hasVideo ? extractYoutubeVideoId(post.youtubeUrl!) : null;
    final cover = post.imageUrl.isNotEmpty
        ? post.imageUrl
        : post.hasClip
            ? post.videoThumbnailUrl
            : (videoId != null ? youtubeThumbnailUrl(videoId) : '');
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.card,
            flexibleSpace: FlexibleSpaceBar(
              background: cover.isEmpty
                  ? Container(color: AppTheme.card)
                  : Image.network(cover,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => Container(color: AppTheme.card)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.orange.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.lock_rounded, color: AppTheme.orange, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          viewer == null
                              ? 'Sign in and reach Level $kDeepDiveLevel to unlock Deep Dive'
                              : 'Deep Dive unlocks at Level $kDeepDiveLevel. '
                                  'You need ${xpToLevel(viewer.xp, kDeepDiveLevel)} more XP.',
                          textAlign: TextAlign.center,
                          style: AppTheme.inter(
                              size: 14, color: Colors.white, weight: FontWeight.w600),
                        ),
                        if (viewer == null) ...[
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: () =>
                                showGuestLoginSheet(context, feature: 'Deep Dive'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cyan,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('LOG IN',
                                style: AppTheme.orbitron(
                                    size: 11, color: Colors.black, weight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    if (_locked) return _lockedView(post);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.card,
            flexibleSpace: FlexibleSpaceBar(background: _banner(post)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppTheme.cyan, borderRadius: BorderRadius.circular(6)),
                    child: post.category.isEmpty
                        ? const Text('LORE ARCHIVE', style: _badgeStyle)
                        : CategoryName(
                            categoryKey: post.category,
                            builder: (_, label) => Text(label, style: _badgeStyle),
                          ),
                  ),
                  if (post.hasFandom) ...[
                    const SizedBox(height: 8),
                    _fandomChip(post),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (post.hasCreator) CreatorByline(creatorId: post.creatorId),
                  if (post.audioUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _NetworkAudioPlayer(url: post.audioUrl),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    post.content,
                    style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                  ),
                  if (post.mediaUrls.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('GALLERY',
                        style: AppTheme.orbitron(size: 10, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    _gallery(post.mediaUrls),
                  ],
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  static const _badgeStyle =
      TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold);

  Widget _gallery(List<String> urls) => SizedBox(
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _FullScreenImage(url: urls[i])),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                urls[i],
                width: 220,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (ctx, e, st) => Container(
                  width: 220,
                  color: AppTheme.card,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: Colors.white24, size: 28),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _fandomChip(Post post) => Material(
        color: AppTheme.accent.withValues(alpha: 0.15),
        shape: StadiumBorder(
            side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => FandomPageScreen(fandomId: post.fandomId)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hub_outlined, color: Colors.white70, size: 13),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    post.fandomName.isEmpty ? 'View fandom' : post.fandomName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(
                        size: 11, color: Colors.white, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.chevron_right, color: Colors.white70, size: 14),
              ],
            ),
          ),
        ),
      );

  Widget _banner(Post post) {
    if (post.hasClip) {
      return ClipPlayer(url: post.videoUrl, thumbnailUrl: post.videoThumbnailUrl);
    }
    if (!post.hasVideo) {
      return post.imageUrl.isNotEmpty
          ? Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, st) => Container(color: AppTheme.card),
            )
          : Container(color: AppTheme.card);
    }
    if (_videoError || _controller == null) {
      return Container(
        color: AppTheme.card,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 32),
            const SizedBox(height: 8),
            Text('Video unavailable',
                style: AppTheme.inter(size: 12, color: Colors.white38)),
          ],
        ),
      );
    }
    return Stack(fit: StackFit.expand, children: [
      YoutubePlayerThumbnail(
        controller: _controller!,
        backgroundColor: AppTheme.card,
        playIcon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
        ),
      ),
      Positioned(
        right: 12,
        bottom: 12,
        child: FullScreenVideoButton(
          size: 42,
          onPressed: () => openFullScreenVideo(
            context,
            videoId: extractYoutubeVideoId(post.youtubeUrl!)!,
            title: post.title,
            inline: _controller,
          ),
        ),
      ),
    ]);
  }
}

/// Full-screen, pinch-zoomable view of one gallery image.
class _FullScreenImage extends StatelessWidget {
  final String url;
  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (ctx, e, st) => Text('Image unavailable',
                  style: AppTheme.inter(size: 13, color: Colors.white54)),
            ),
          ),
        ),
      );
}

/// Streams a post's podcast audio with video_player (it plays audio too).
class _NetworkAudioPlayer extends StatefulWidget {
  final String url;
  const _NetworkAudioPlayer({required this.url});

  @override
  State<_NetworkAudioPlayer> createState() => _NetworkAudioPlayerState();
}

class _NetworkAudioPlayerState extends State<_NetworkAudioPlayer> {
  VideoPlayerController? _c;
  bool _loading = false;
  bool _error = false;

  void _tick() {
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) {
      setState(() => _error = true);
      return;
    }
    setState(() => _loading = true);
    final c = VideoPlayerController.networkUrl(uri);
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      c.addListener(_tick);
      await c.play();
      if (!mounted) return;
      setState(() {
        _c = c;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Podcast audio failed: $e');
      await c.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // Release the native player when leaving the screen.
    _c?.removeListener(_tick);
    _c?.dispose();
    super.dispose();
  }

  static String _t(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final playing = c?.value.isPlaying ?? false;
    final total = c?.value.duration ?? Duration.zero;
    final pos = c?.value.position ?? Duration.zero;
    final maxMs = total.inMilliseconds.toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: _error
          ? Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                const Icon(Icons.headset_off_outlined, color: Colors.white38, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("This audio can't be played right now. Check your connection.",
                      style: AppTheme.inter(size: 12, color: Colors.white54)),
                ),
              ]),
            )
          : Row(children: [
              _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.cyan)),
                    )
                  : IconButton(
                      icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: AppTheme.cyan, size: 36),
                      onPressed: () {
                        if (c == null) {
                          _start();
                        } else {
                          playing ? c.pause() : c.play();
                        }
                      },
                    ),
              Expanded(
                child: c == null
                    ? Text(_loading ? 'Loading podcast…' : 'Play podcast',
                        style: AppTheme.inter(size: 13, color: Colors.white70))
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            overlayShape: SliderComponentShape.noOverlay,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: maxMs <= 0
                                ? 0
                                : pos.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
                            max: maxMs <= 0 ? 1 : maxMs,
                            activeColor: AppTheme.cyan,
                            inactiveColor: Colors.white12,
                            onChanged: maxMs <= 0
                                ? null
                                : (v) => c.seekTo(Duration(milliseconds: v.round())),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${_t(pos)} / ${_t(total)}',
                            style: AppTheme.inter(size: 11, color: Colors.white54)),
                      ]),
              ),
            ]),
    );
  }
}
