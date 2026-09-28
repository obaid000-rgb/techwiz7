import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/bookmark_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_name.dart';
import '../../widgets/clip_player.dart';

/// Renders a bookmarked post's saved copy entirely from the device — no
/// network calls — so it works with no connection at all: cover, text,
/// gallery images, the uploaded clip and podcast audio. YouTube videos and
/// audio that wasn't saved say they need internet.
class OfflinePostDetailScreen extends StatelessWidget {
  final BookmarkCopy copy;
  const OfflinePostDetailScreen({super.key, required this.copy});

  static const _badgeStyle = TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold);

  Widget _localImage(String? path, {double? height}) => path != null && !kIsWeb
      ? Image.file(File(path),
          fit: BoxFit.cover,
          height: height,
          width: double.infinity,
          errorBuilder: (c, e, s) => _missing(Icons.image_not_supported_outlined, 'Image not saved', height))
      : _missing(Icons.cloud_off_outlined, 'Image needs internet', height);

  Widget _missing(IconData icon, String text, double? height) => Container(
        height: height,
        color: AppTheme.card,
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white24, size: 28),
          const SizedBox(height: 6),
          Text(text, style: AppTheme.inter(size: 11, color: Colors.white38)),
        ]),
      );

  Widget _note(IconData icon, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white38, size: 28),
          const SizedBox(height: 8),
          Text(text, style: AppTheme.inter(size: 13, color: Colors.white60, weight: FontWeight.w600)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final post = copy.post;
    final gallery = post.mediaUrls;
    final meta = [
      if (post.fandomName.isNotEmpty) post.fandomName,
      if (post.creatorName.isNotEmpty) 'by ${post.creatorName}',
      '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
    ].join(' · ');
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.card,
            flexibleSpace: FlexibleSpaceBar(
              background: copy.coverPath != null || copy.videoThumbnailPath != null
                  ? _localImage(copy.coverPath ?? copy.videoThumbnailPath)
                  : Container(
                      color: AppTheme.card,
                      alignment: Alignment.center,
                      child: const Icon(Icons.article_outlined, color: Colors.white24, size: 40),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (copy.noLongerAvailable) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.5)),
                      ),
                      child: Text('No longer available online',
                          style: AppTheme.inter(size: 12, color: AppTheme.orange, weight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (copy.videoPath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipPlayer(filePath: copy.videoPath, thumbnailPath: copy.videoThumbnailPath),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (post.hasClip || post.hasVideo) ...[
                    _note(Icons.wifi_off_rounded, 'This video needs internet'),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.cyan, borderRadius: BorderRadius.circular(6)),
                        child: post.category.isEmpty
                            ? const Text('LORE ARCHIVE', style: _badgeStyle)
                            : CategoryName(
                                categoryKey: post.category,
                                builder: (_, label) => Text(label, style: _badgeStyle),
                              ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.offline_pin, color: AppTheme.accent, size: 14),
                      const SizedBox(width: 3),
                      Text('SAVED', style: AppTheme.inter(size: 10, color: AppTheme.accent)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('${post.contentType} · $meta', style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                  if (post.audioUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    copy.audioPath != null && !kIsWeb
                        ? _LocalAudioPlayer(path: copy.audioPath!)
                        : _note(Icons.headset_off_outlined, 'Audio needs internet'),
                  ],
                  const SizedBox(height: 16),
                  Text(post.content, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
                  if (gallery.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('GALLERY', style: AppTheme.orbitron(size: 10, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    for (final url in gallery) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _localImage(copy.fileFor(url), height: 220),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plays a saved podcast file with video_player (it plays audio too).
class _LocalAudioPlayer extends StatefulWidget {
  final String path;
  const _LocalAudioPlayer({required this.path});

  @override
  State<_LocalAudioPlayer> createState() => _LocalAudioPlayerState();
}

class _LocalAudioPlayerState extends State<_LocalAudioPlayer> {
  VideoPlayerController? _c;
  bool _error = false;

  Future<void> _start() async {
    final c = VideoPlayerController.file(File(widget.path));
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      c.addListener(() {
        if (mounted) setState(() {});
      });
      await c.play();
      setState(() => _c = c);
    } catch (e) {
      debugPrint('Saved audio failed: $e');
      await c.dispose();
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    // Release the native player when leaving the screen.
    _c?.dispose();
    super.dispose();
  }

  static String _t(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final playing = c?.value.isPlaying ?? false;
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
              child: Text("This audio can't be played right now",
                  style: AppTheme.inter(size: 12, color: Colors.white54)),
            )
          : Row(children: [
              IconButton(
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
                    ? Text('Play podcast', style: AppTheme.inter(size: 13, color: Colors.white70))
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        VideoProgressIndicator(c,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                                playedColor: AppTheme.cyan, backgroundColor: Colors.white12)),
                        const SizedBox(height: 4),
                        Text('${_t(c.value.position)} / ${_t(c.value.duration)}',
                            style: AppTheme.inter(size: 11, color: Colors.white54)),
                      ]),
              ),
            ]),
    );
  }
}
