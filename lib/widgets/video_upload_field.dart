import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';
import 'clip_player.dart';

/// Short-video counterpart of [ImageUploadField]: tap to pick from the
/// gallery or record, the clip is checked (30 s / 30 MB), uploaded to
/// Cloudinary with a progress bar, then previewed. A failed upload offers
/// "Tap to retry" with the same clip.
class VideoUploadField extends StatefulWidget {
  final String? initialUrl;
  final String? initialThumbnailUrl;
  final ValueChanged<UploadedVideo> onUploaded;
  final ValueChanged<bool>? onBusyChanged;
  final Color accentColor;
  final double height;

  const VideoUploadField({
    super.key,
    this.initialUrl,
    this.initialThumbnailUrl,
    required this.onUploaded,
    this.onBusyChanged,
    this.accentColor = AppTheme.cyan,
    this.height = 190,
  });

  static const maxSeconds = 30;
  static const maxBytes = 30 * 1024 * 1024;

  @override
  State<VideoUploadField> createState() => _VideoUploadFieldState();
}

class _VideoUploadFieldState extends State<VideoUploadField> {
  late String? _url = (widget.initialUrl?.isEmpty ?? true) ? null : widget.initialUrl;
  late String? _thumb = widget.initialThumbnailUrl;
  bool _uploading = false;
  double _progress = 0;
  String? _error; // upload failed: tap retries the same clip
  String? _rejected; // clip refused before upload (too long / too big)
  XFile? _pending;
  int _pendingSeconds = 0;

  void _setBusy(bool busy) {
    setState(() => _uploading = busy);
    widget.onBusyChanged?.call(busy);
  }

  Future<void> _showSourcePicker() async {
    if (_uploading) return;
    if (_error != null && _pending != null) {
      await _upload();
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.video_library_outlined, color: widget.accentColor),
            title: Text('Choose from Gallery', style: AppTheme.inter(size: 14)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          if (!kIsWeb)
            ListTile(
              leading: Icon(Icons.videocam_outlined, color: widget.accentColor),
              title: Text('Record a Video', style: AppTheme.inter(size: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ListTile(
            leading: const Icon(Icons.close, color: Colors.grey),
            title: Text('Cancel', style: AppTheme.inter(size: 14, color: Colors.grey)),
            onTap: () => Navigator.pop(ctx),
          ),
        ]),
      ),
    );
    if (source != null) await _pick(source);
  }

  Future<void> _pick(ImageSource source) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickVideo(
          source: source, maxDuration: const Duration(seconds: VideoUploadField.maxSeconds));
    } catch (e) {
      debugPrint('Video pick failed: $e');
      setState(() => _rejected = 'Could not open the video. Try another one.');
      return;
    }
    if (file == null || !mounted) return;
    if (await file.length() > VideoUploadField.maxBytes) {
      setState(() => _rejected = 'Videos must be 30 MB or smaller');
      return;
    }
    // Duration check: read the clip's real length on the device with
    // video_player BEFORE uploading. The camera's maxDuration is only a hint
    // and gallery clips have no limit, so anything longer than 30 seconds
    // (with half a second of rounding slack) is rejected here and never
    // sent to Cloudinary.
    final probe = kIsWeb
        ? VideoPlayerController.networkUrl(Uri.parse(file.path))
        : VideoPlayerController.file(File(file.path));
    Duration length;
    try {
      await probe.initialize();
      length = probe.value.duration;
    } catch (e) {
      debugPrint('Video length check failed: $e');
      if (mounted) setState(() => _rejected = 'Could not read this video. Try another one.');
      return;
    } finally {
      await probe.dispose();
    }
    if (!mounted) return;
    if (length > const Duration(seconds: VideoUploadField.maxSeconds, milliseconds: 500)) {
      setState(() => _rejected = 'Videos must be 30 seconds or shorter');
      return;
    }
    _pending = file;
    _pendingSeconds = (length.inMilliseconds / 1000).round();
    await _upload();
  }

  Future<void> _upload() async {
    final file = _pending;
    if (file == null) return;
    setState(() {
      _error = null;
      _rejected = null;
      _progress = 0;
    });
    _setBusy(true);
    try {
      final up = await CloudinaryService.instance.uploadVideo(file, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (!mounted) return;
      final result = UploadedVideo(up.url, up.thumbnailUrl, _pendingSeconds > 0 ? _pendingSeconds : up.durationSeconds);
      setState(() {
        _url = result.url;
        _thumb = result.thumbnailUrl;
        _pending = null;
      });
      _setBusy(false);
      widget.onUploaded(result);
    } catch (e) {
      debugPrint('Video upload failed: $e');
      if (!mounted) return;
      setState(() => _error = 'Upload failed');
      _setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = (_error != null || _rejected != null)
        ? Colors.redAccent
        : widget.accentColor.withValues(alpha: 0.4);
    final Widget body;
    if (_uploading) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Uploading video… ${(_progress * 100).round()}%',
                style: AppTheme.inter(size: 12, color: Colors.white70)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 6,
                color: widget.accentColor,
                backgroundColor: Colors.white12,
              ),
            ),
          ]),
        ),
      );
    } else if (_error != null) {
      body = _message(Icons.error_outline, _error!, 'Tap to retry');
    } else if (_url != null) {
      body = Stack(fit: StackFit.expand, children: [
        ClipPlayer(url: _url, thumbnailUrl: _thumb),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _showSourcePicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.swap_horiz, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('Replace', style: AppTheme.inter(size: 11, color: Colors.white)),
                ]),
              ),
            ),
          ),
        ),
      ]);
    } else {
      body = _rejected != null
          ? _message(Icons.block, _rejected!, 'Tap to choose another video')
          : Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.video_call_outlined, color: widget.accentColor, size: 34),
                const SizedBox(height: 8),
                Text('Tap to add a short video', style: AppTheme.inter(size: 13, color: Colors.white70)),
                const SizedBox(height: 2),
                Text('Up to 30 seconds and 30 MB', style: AppTheme.inter(size: 11, color: Colors.grey)),
              ]),
            );
    }
    return GestureDetector(
      // The preview handles its own taps (play / Replace).
      onTap: _url != null && _error == null && !_uploading ? null : _showSourcePicker,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(11), child: body),
      ),
    );
  }

  Widget _message(IconData icon, String title, String hint) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.redAccent, size: 28),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: AppTheme.inter(size: 12, color: Colors.redAccent)),
            const SizedBox(height: 4),
            Text(hint, style: AppTheme.inter(size: 11, color: Colors.grey)),
          ]),
        ),
      );
}
