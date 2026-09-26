import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

/// Reusable widget that combines image picking, Cloudinary upload, and preview.
///
/// Set [isCircular] = true for a circular avatar variant (profile).
/// Leave false (default) for a rectangular banner variant (admin forms).
///
/// [onUploaded] fires once with the Cloudinary secure_url on success.
class ImageUploadField extends StatefulWidget {
  final String? initialUrl;
  final ValueChanged<String> onUploaded;
  final Color accentColor;
  final double height;
  final bool isCircular;
  final double circleRadius;

  const ImageUploadField({
    super.key,
    this.initialUrl,
    required this.onUploaded,
    this.accentColor = AppTheme.accent,
    this.height = 180,
    this.isCircular = false,
    this.circleRadius = 46,
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  late String? _url;
  bool _uploading = false;
  String? _error;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final raw = widget.initialUrl;
    _url = (raw == null || raw.isEmpty) ? null : raw;
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (file == null) return; // user cancelled
      if (!mounted) return;
      setState(() {
        _uploading = true;
        _error = null;
      });
      final url = await CloudinaryService.instance.uploadImage(file);
      if (!mounted) return;
      setState(() {
        _url = url;
        _uploading = false;
      });
      widget.onUploaded(url);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        debugPrint('Image upload failed: $e');
        _error = 'Upload failed';
      });
    }
  }

  Future<void> _showSourcePicker() async {
    if (_uploading) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: widget.accentColor),
                title: Text('Choose from Gallery',
                    style: AppTheme.inter(size: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined,
                    color: widget.accentColor),
                title: Text('Take a Photo', style: AppTheme.inter(size: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: Text('Cancel',
                    style: AppTheme.inter(size: 14, color: Colors.grey)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      widget.isCircular ? _circularWidget() : _rectWidget();

  // ── Circular avatar variant ───────────────────────────────────────────────

  Widget _circularWidget() {
    return GestureDetector(
      onTap: _showSourcePicker,
      child: Center(
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [widget.accentColor, AppTheme.cyan]),
              ),
              child: _uploading
                  ? CircleAvatar(
                      radius: widget.circleRadius,
                      backgroundColor: AppTheme.card,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: widget.accentColor),
                      ),
                    )
                  : CircleAvatar(
                      radius: widget.circleRadius,
                      backgroundImage:
                          _url != null ? NetworkImage(_url!) : null,
                      backgroundColor: AppTheme.card,
                      child: _url == null
                          ? Icon(Icons.person_outline,
                              size: widget.circleRadius * 0.75,
                              color: Colors.grey)
                          : null,
                    ),
            ),
            if (!_uploading)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.bg, width: 2),
                  ),
                  child:
                      const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            if (_error != null && !_uploading)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline,
                      size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Rectangular banner variant ─────────────────────────────────────────────

  Widget _rectWidget() {
    return GestureDetector(
      onTap: _showSourcePicker,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _error != null
                ? Colors.redAccent
                : widget.accentColor.withValues(alpha: 0.4),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: _uploading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: widget.accentColor),
                      ),
                      const SizedBox(height: 10),
                      Text('Uploading…',
                          style:
                              AppTheme.inter(size: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 28),
                            const SizedBox(height: 8),
                            Text('Upload failed',
                                style: AppTheme.inter(
                                    size: 12, color: Colors.redAccent)),
                            const SizedBox(height: 4),
                            Text('Tap to retry',
                                style: AppTheme.inter(
                                    size: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  : _url != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(_url!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.edit,
                                    color: widget.accentColor, size: 16),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined,
                                  color: widget.accentColor, size: 32),
                              const SizedBox(height: 8),
                              Text('Tap to upload image',
                                  style: AppTheme.inter(
                                      size: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text('Optional',
                                  style: AppTheme.inter(
                                      size: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
        ),
      ),
    );
  }
}
