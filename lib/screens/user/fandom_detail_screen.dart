import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/post.dart';
import '../../services/offline_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/youtube_utils.dart';

class FandomDetailScreen extends StatefulWidget {
  final Post post;

  const FandomDetailScreen({super.key, required this.post});

  @override
  State<FandomDetailScreen> createState() => _FandomDetailScreenState();
}

class _FandomDetailScreenState extends State<FandomDetailScreen> {
  YoutubePlayerController? _controller;
  bool _videoError = false;
  bool? _isSavedOffline;
  bool _savingOffline = false;

  @override
  void initState() {
    super.initState();
    OfflineService.instance.isSaved(widget.post.id).then((saved) {
      if (mounted) setState(() => _isSavedOffline = saved);
    });
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

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
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
                    child: Text(
                      post.category.isEmpty ? 'LORE ARCHIVE' : post.category.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    post.content,
                    style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _offlineButton(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _toggleOffline() async {
    setState(() => _savingOffline = true);
    if (_isSavedOffline == true) {
      await OfflineService.instance.removeOffline(widget.post.id);
    } else {
      await OfflineService.instance.saveOffline(widget.post);
    }
    if (!mounted) return;
    setState(() {
      _isSavedOffline = !(_isSavedOffline ?? false);
      _savingOffline = false;
    });
  }

  Widget _offlineButton() {
    final saved = _isSavedOffline ?? false;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: (_isSavedOffline == null || _savingOffline) ? null : _toggleOffline,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: saved ? AppTheme.accent : AppTheme.border),
          backgroundColor: saved ? AppTheme.accent.withValues(alpha: 0.12) : null,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: _savingOffline
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
              )
            : Icon(saved ? Icons.offline_pin : Icons.download_outlined,
                color: saved ? AppTheme.accent : Colors.white70, size: 18),
        label: Text(
          saved ? 'Saved for Offline' : 'Save for Offline',
          style: AppTheme.inter(
              size: 12, color: saved ? AppTheme.accent : Colors.white70, weight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _banner(Post post) {
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
    return YoutubePlayerThumbnail(
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
    );
  }
}
