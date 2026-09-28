import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../theme/app_theme.dart';

/// Opens [VideoPlayerScreen] straight into landscape full screen. If an
/// inline player is already playing it, that player is paused and the full
/// screen player continues from the same moment.
Future<void> openFullScreenVideo(
  BuildContext context, {
  required String videoId,
  required String title,
  YoutubePlayerController? inline,
}) async {
  double start = 0;
  if (inline != null) {
    try {
      start = await inline.currentTime.timeout(const Duration(seconds: 1));
      await inline.pauseVideo().timeout(const Duration(seconds: 1));
    } catch (_) {
      // Inline player not started/ready yet: start from the beginning.
    }
  }
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VideoPlayerScreen(
        videoId: videoId,
        title: title,
        startSeconds: start,
        startFullScreen: true,
      ),
    ),
  );
}

/// Small round "⛶" button placed over an inline video.
class FullScreenVideoButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;
  const FullScreenVideoButton({super.key, required this.onPressed, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: 'Full screen',
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.fullscreen_rounded, color: Colors.white, size: size * 0.62),
          ),
        ),
      ),
    );
  }
}

/// Full-screen YouTube player inside the app.
///
/// - Portrait: title bar, the player with full controls (play/pause, seek,
///   speed, full-screen button) and a "Watch full screen" button.
/// - Full screen: the phone turns to landscape, status/navigation bars hide
///   and the video fills the screen. Enter it with either button, or just
///   by rotating the phone; rotate back (or press back / the exit button)
///   to leave it.
/// Leaving this screen always restores normal orientation and system bars.
class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final double startSeconds;
  /// Open straight into landscape full screen (the ⛶ button on a card).
  final bool startFullScreen;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    this.startSeconds = 0,
    this.startFullScreen = false,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final YoutubePlayerController _controller = YoutubePlayerController.fromVideoId(
    videoId: widget.videoId,
    autoPlay: true,
    startSeconds: widget.startSeconds > 0 ? widget.startSeconds : null,
  );

  @override
  void initState() {
    super.initState();
    // The player calls this whenever full screen is entered or left — from
    // its own button, our buttons, or the phone rotating.
    _controller.setFullScreenListener(_onFullScreenChanged);
    if (widget.startFullScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.enterFullScreen();
      });
    }
  }

  bool get _isFullScreen => _controller.value.fullScreenOption.enabled;

  bool get _deviceIsPortrait {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    return size.height >= size.width;
  }

  Future<void> _onFullScreenChanged(bool fullScreen) async {
    if (fullScreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      // Started by a button while upright: turn the phone sideways. If the
      // user rotated into full screen themselves, leave rotation free so
      // turning the phone back upright exits full screen again.
      if (_deviceIsPortrait) {
        await SystemChrome.setPreferredOrientations(
            [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      }
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      // Back upright: allow rotating into full screen again.
      await SystemChrome.setPreferredOrientations(const []);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // Never leave the rest of the app sideways or with hidden system bars.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const []);
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back while in full screen leaves full screen first, then the screen.
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller.exitFullScreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              final landscape = orientation == Orientation.landscape;
              final player = YoutubePlayer(
                controller: _controller,
                backgroundColor: Colors.black,
              );
              if (landscape) {
                // Landscape: the video fills the screen, with an exit button.
                return Stack(children: [
                  Center(child: player),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _roundButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Back',
                      onTap: () => Navigator.maybePop(context),
                    ),
                  ),
                ]);
              }
              return Column(children: [
                Row(children: [
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Text(widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.orbitron(size: 13)),
                  ),
                  const SizedBox(width: 12),
                ]),
                Expanded(child: Center(child: player)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _controller.enterFullScreen(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                        label: Text('WATCH FULL SCREEN',
                            style: AppTheme.orbitron(size: 11, weight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.screen_rotation_rounded, color: AppTheme.textMuted, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('Or just rotate your phone',
                            style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                      ),
                    ]),
                  ]),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }

  Widget _roundButton({required IconData icon, required String tooltip, required VoidCallback onTap}) =>
      Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onTap,
        ),
      );
}
