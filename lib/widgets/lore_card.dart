import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../screens/explore/fandom_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/levels.dart';
import '../utils/youtube_utils.dart';
import 'category_name.dart';
import 'deep_dive_lock.dart';
import 'trending_badge.dart';
import '../screens/explore/video_player_screen.dart';

/// Shared post/lore card used across the Category Detail, content-type
/// filter, and Explore Latest list screens — mirrors the card styling
/// already established on Home's lore list.
class LoreCard extends StatelessWidget {
  final Post post;
  const LoreCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.fandomName.isNotEmpty) return _card(context, post.fandomName.toUpperCase());
    if (post.category.isEmpty) return _card(context, '');
    // No fandom name: label with the category's display name, not its key.
    return CategoryName(
      categoryKey: post.category,
      builder: (context, name) => _card(context, name),
    );
  }

  Widget _card(BuildContext context, String label) {
    final badge = label.isEmpty ? 'LORE ARCHIVE' : label;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: PostMediaThumbnail(post: post, height: 144),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Positioned(top: 8, right: 8, child: TrendingBadge(postId: post.id)),
              if (isDeepDive(post))
                Positioned(left: 8, bottom: 8, child: const DeepDiveLockBadge()),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.orbitron(size: 13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                PostExcerpt(
                  post: post,
                  style:
                      AppTheme.inter(size: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_outlined,
                              color: Colors.grey, size: 12),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              [
                                if (label.isNotEmpty) label,
                                if (post.creatorName.isNotEmpty) 'By ${post.creatorName}',
                              ].join('  ·  '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppTheme.inter(size: 10, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FandomDetailScreen(post: post)),
                      ),
                      child: Row(
                        children: [
                          Text('Read Archive',
                              style: AppTheme.inter(
                                  size: 12,
                                  color: AppTheme.cyan,
                                  weight: FontWeight.w600)),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward,
                              size: 13, color: AppTheme.cyan),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// Shared thumbnail for any post card. A video post plays inline, in place,
/// on tap — it never navigates to another screen for playback. A plain
/// image post renders exactly as before. Used by every card surface so a
/// video looks and behaves the same wherever it appears.
class PostMediaThumbnail extends StatefulWidget {
  final Post post;
  // Leave null when the parent already provides bounded constraints
  // (e.g. inside Expanded) — a fixed value wraps the thumbnail in its own
  // SizedBox instead, for parents that don't bound it themselves.
  final double? height;
  final double playIconSize;
  const PostMediaThumbnail({
    super.key,
    required this.post,
    this.height,
    this.playIconSize = 40,
  });

  @override
  State<PostMediaThumbnail> createState() => _PostMediaThumbnailState();
}

class _PostMediaThumbnailState extends State<PostMediaThumbnail> {
  YoutubePlayerController? _controller;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(PostMediaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.youtubeUrl != widget.post.youtubeUrl) {
      _controller?.close();
      _controller = null;
      _videoError = false;
      _initController();
    }
  }

  void _initController() {
    if (!widget.post.hasVideo) return;
    final videoId = extractYoutubeVideoId(widget.post.youtubeUrl!);
    if (videoId == null) {
      _videoError = true;
      return;
    }
    _videoId = videoId;
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
    )..stream.listen((value) {
        if (value.hasError && mounted) setState(() => _videoError = true);
      });
  }

  String? _videoId;

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (widget.post.hasVideo && _controller != null && !_videoError) {
      final thumbnail = YoutubePlayerThumbnail(
        controller: _controller!,
        backgroundColor: AppTheme.bg,
        playIcon: Container(
          padding: EdgeInsets.all(widget.playIconSize * 0.25),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.play_arrow,
              color: Colors.white, size: widget.playIconSize),
        ),
      );
      // Full-screen button, except on tiny thumbnails (Home's post rows),
      // where it would cover the video; those rows open the post page,
      // which has one.
      final roomy = widget.height == null || widget.height! >= 110;
      content = !roomy
          ? thumbnail
          : Stack(fit: StackFit.expand, children: [
              thumbnail,
              Positioned(
                right: 8,
                bottom: 8,
                child: FullScreenVideoButton(
                  onPressed: () => openFullScreenVideo(
                    context,
                    videoId: _videoId!,
                    title: widget.post.title,
                    inline: _controller,
                  ),
                ),
              ),
            ]);
    } else if (widget.post.hasVideo && _videoError) {
      content = _errorPlaceholder();
    } else if (widget.post.hasClip) {
      // Uploaded clip: its Cloudinary thumbnail with the play badge and
      // duration; the card opens Content Detail, which plays it.
      final secs = widget.post.durationSeconds;
      content = Stack(fit: StackFit.expand, children: [
        widget.post.videoThumbnailUrl.isNotEmpty
            ? Image.network(widget.post.videoThumbnailUrl,
                fit: BoxFit.cover, errorBuilder: (ctx, e, st) => _placeholder())
            : _placeholder(),
        Center(
          child: Container(
            padding: EdgeInsets.all(widget.playIconSize * 0.25),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow, color: Colors.white, size: widget.playIconSize),
          ),
        ),
        if (secs > 0)
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}',
                  style: AppTheme.inter(size: 10, color: Colors.white, weight: FontWeight.w700)),
            ),
          ),
      ]);
    } else {
      content = widget.post.imageUrl.isNotEmpty
          ? Image.network(
              widget.post.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (ctx, e, st) => _placeholder(),
            )
          : _placeholder();
    }
    return widget.height == null
        ? content
        : SizedBox(height: widget.height, width: double.infinity, child: content);
  }

  Widget _placeholder() => Container(
        color: AppTheme.bg,
        alignment: Alignment.center,
        child: const Icon(Icons.article_outlined,
            color: Colors.white12, size: 36),
      );

  Widget _errorPlaceholder() => Container(
        color: AppTheme.bg,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 26),
            const SizedBox(height: 6),
            Text('Video unavailable',
                style: AppTheme.inter(size: 10, color: Colors.white38)),
          ],
        ),
      );
}

/// Lock badge on Deep Dive cards while the viewer is below Level DEEP_DIVE_LEVEL
/// (hidden for admins and for fans who have unlocked Deep Dive).
class DeepDiveLockBadge extends StatelessWidget {
  const DeepDiveLockBadge({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UserData?>(
        valueListenable: AuthService.instance.userNotifier,
        builder: (context, user, _) {
          final open = canViewDeepDive(user);
          if (open) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.orange.withValues(alpha: 0.8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, color: AppTheme.orange, size: 12),
                const SizedBox(width: 4),
                Text('Level $DEEP_DIVE_LEVEL',
                    style: AppTheme.inter(size: 10, color: Colors.white, weight: FontWeight.w700)),
              ],
            ),
          );
        },
      );
}
