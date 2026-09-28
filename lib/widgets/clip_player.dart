import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

/// Inline player for an uploaded short clip. Shows the thumbnail with a
/// play button; tapping starts playback with play/pause, a progress bar,
/// mute and replay. Plays from [url] (online) or [filePath] (offline copy).
class ClipPlayer extends StatefulWidget {
  final String? url;
  final String? filePath;
  final String? thumbnailUrl;
  final String? thumbnailPath;

  const ClipPlayer({super.key, this.url, this.filePath, this.thumbnailUrl, this.thumbnailPath});

  @override
  State<ClipPlayer> createState() => _ClipPlayerState();
}

class _ClipPlayerState extends State<ClipPlayer> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _error = false;
  bool _muted = false;

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final c = widget.filePath != null && !kIsWeb
        ? VideoPlayerController.file(File(widget.filePath!))
        : VideoPlayerController.networkUrl(Uri.parse(widget.url ?? ''));
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      c.addListener(_onTick);
      await c.setVolume(_muted ? 0 : 1);
      await c.play();
      setState(() {
        _controller = c;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Clip failed to load: $e');
      await c.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !mounted) return;
    if (c.value.hasError && !_error) {
      setState(() => _error = true);
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    // Dispose the controller when leaving the screen: it holds the native
    // player and decoder, which keep running (and playing sound) otherwise.
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  Widget _thumbnail() {
    if (widget.thumbnailPath != null && !kIsWeb) {
      return Image.file(File(widget.thumbnailPath!), fit: BoxFit.cover, errorBuilder: (c, e, s) => _blank());
    }
    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      return Image.network(widget.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => _blank());
    }
    return _blank();
  }

  Widget _blank() => Container(color: AppTheme.card);

  Widget _roundButton(IconData icon, VoidCallback onTap, {double size = 36}) => Material(
        color: Colors.black.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: size),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        color: AppTheme.card,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.white38, size: 32),
          const SizedBox(height: 8),
          Text("This video can't be played right now",
              textAlign: TextAlign.center, style: AppTheme.inter(size: 12, color: Colors.white54)),
        ]),
      );
    }
    final c = _controller;
    if (c == null) {
      return Stack(fit: StackFit.expand, children: [
        _thumbnail(),
        Center(
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : _roundButton(Icons.play_arrow_rounded, _start),
        ),
      ]);
    }
    final v = c.value;
    final ended = v.isInitialized && v.position >= v.duration && !v.isPlaying;
    return Container(
      color: Colors.black,
      child: Stack(children: [
        Center(
          child: AspectRatio(
            aspectRatio: v.aspectRatio == 0 ? 16 / 9 : v.aspectRatio,
            child: VideoPlayer(c),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => v.isPlaying ? c.pause() : c.play(),
          ),
        ),
        if (!v.isPlaying)
          Center(
            child: _roundButton(ended ? Icons.replay_rounded : Icons.play_arrow_rounded, () async {
              if (ended) await c.seekTo(Duration.zero);
              await c.play();
            }),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: Row(children: [
              IconButton(
                tooltip: v.isPlaying ? 'Pause' : 'Play',
                icon: Icon(v.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 22),
                onPressed: () => v.isPlaying ? c.pause() : c.play(),
              ),
              Expanded(
                child: VideoProgressIndicator(
                  c,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppTheme.cyan,
                    bufferedColor: Colors.white30,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
              IconButton(
                tooltip: _muted ? 'Unmute' : 'Mute',
                icon: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white, size: 20),
                onPressed: () {
                  setState(() => _muted = !_muted);
                  c.setVolume(_muted ? 0 : 1);
                },
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
