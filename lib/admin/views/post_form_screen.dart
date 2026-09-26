import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/youtube_utils.dart';
import '../../widgets/category_picker_field.dart';
import '../../widgets/image_upload_field.dart';

class PostFormScreen extends StatefulWidget {
  final Post? existing;
  const PostFormScreen({super.key, this.existing});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _titleCtr = TextEditingController();
  final _contentCtr = TextEditingController();
  final _youtubeUrlCtr = TextEditingController();
  String? _category;
  String _imageUrl = '';
  String _contentType = 'News';
  String _status = 'active';
  String _contentDepth = '';
  String _deepDiveType = '';
  bool _isFandomOfTheDay = false;
  bool _saving = false;
  String? _error;
  String? _youtubeVideoId;
  String? _youtubeFieldError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtr.text = e.title;
      _contentCtr.text = e.content;
      _imageUrl = e.imageUrl;
      _category = e.category.isEmpty ? null : e.category;
      _contentType = e.contentType;
      _status = e.status;
      _contentDepth = e.contentDepth;
      _deepDiveType = e.deepDiveType;
      _isFandomOfTheDay = e.isFandomOfTheDay;
      _youtubeUrlCtr.text = e.youtubeUrl ?? '';
      _youtubeVideoId = extractYoutubeVideoId(_youtubeUrlCtr.text);
    }
    _youtubeUrlCtr.addListener(_onYoutubeUrlChanged);
  }

  void _onYoutubeUrlChanged() {
    final text = _youtubeUrlCtr.text.trim();
    setState(() {
      if (text.isEmpty) {
        _youtubeVideoId = null;
        _youtubeFieldError = null;
        return;
      }
      final id = extractYoutubeVideoId(text);
      _youtubeVideoId = id;
      _youtubeFieldError =
          id == null ? 'That doesn\'t look like a valid YouTube link.' : null;
    });
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _contentCtr.dispose();
    _youtubeUrlCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? 'Edit Lore Post' : 'New Lore Post',
            style: AppTheme.orbitron(size: 13)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: AppTheme.cyan.withValues(alpha: 0.3)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Text(_error!,
                    style: AppTheme.inter(
                        size: 12, color: Colors.redAccent)),
              ),
            _label('Title'),
            _textField(_titleCtr, hint: 'Enter lore post title'),
            const SizedBox(height: 16),
            _label('Category'),
            CategoryPickerField(
              value: _category,
              accentColor: AppTheme.cyan,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),
            _label('Content'),
            _textField(_contentCtr,
                hint: 'Write the lore content...', maxLines: 6),
            const SizedBox(height: 16),
            _label('Image (optional)'),
            ImageUploadField(
              initialUrl: _imageUrl.isEmpty ? null : _imageUrl,
              onUploaded: (url) => setState(() => _imageUrl = url),
              accentColor: AppTheme.cyan,
            ),
            const SizedBox(height: 16),
            _label('YouTube URL (optional)'),
            _textField(_youtubeUrlCtr,
                hint: 'https://www.youtube.com/watch?v=… or https://youtu.be/…'),
            if (_youtubeFieldError != null) ...[
              const SizedBox(height: 6),
              Text(_youtubeFieldError!,
                  style: AppTheme.inter(size: 11, color: Colors.redAccent)),
            ],
            if (_youtubeVideoId != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      youtubeThumbnailUrl(_youtubeVideoId!),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        height: 160,
                        color: AppTheme.card,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined,
                            color: Colors.white24, size: 32),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _label('Content Type'),
            _dropdown(
              _contentType,
              kPostContentTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              (val) => setState(() => _contentType = val ?? _contentType),
            ),
            const SizedBox(height: 16),
            _label('Status'),
            _dropdown(
              _status,
              const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              (val) => setState(() => _status = val ?? _status),
            ),
            const SizedBox(height: 16),
            _label('Depth (Beginner / Deep Dive filter)'),
            _dropdown(
              _contentDepth,
              const [
                DropdownMenuItem(value: '', child: Text('Unset')),
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'deep', child: Text('Deep Dive')),
              ],
              (val) => setState(() => _contentDepth = val ?? _contentDepth),
            ),
            if (_contentDepth == 'deep') ...[
              const SizedBox(height: 16),
              _label('Deep Dive type (Trivia / Advanced Lore / Interviews tab)'),
              _dropdown(
                _deepDiveType,
                [
                  const DropdownMenuItem(value: '', child: Text('Unset (All tab only)')),
                  for (final t in kDeepDiveTypes)
                    DropdownMenuItem(value: t, child: Text(kDeepDiveTypeLabels[t]!)),
                ],
                (val) => setState(() => _deepDiveType = val ?? _deepDiveType),
              ),
            ],
            const SizedBox(height: 16),
            _todaysFandomToggle(),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Text('SAVE POST',
                        style: AppTheme.orbitron(
                            size: 12,
                            color: Colors.black,
                            weight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<DropdownMenuItem<String>> items,
    void Function(String?) onChanged,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.card,
          underline: const SizedBox.shrink(),
          style: AppTheme.inter(size: 13, color: Colors.white),
          items: items,
          onChanged: onChanged,
        ),
      );

  Widget _todaysFandomToggle() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today\'s Fandom',
                      style: AppTheme.inter(
                          size: 13, color: Colors.white, weight: FontWeight.w600)),
                  Text('Featured as the single highlight on the Lore tab',
                      style: AppTheme.inter(size: 10, color: Colors.grey)),
                ],
              ),
            ),
            Switch(
              value: _isFandomOfTheDay,
              activeThumbColor: AppTheme.cyan,
              onChanged: (val) => setState(() => _isFandomOfTheDay = val),
            ),
          ],
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: AppTheme.inter(size: 12, color: Colors.grey)),
      );

  Widget _textField(TextEditingController ctrl,
      {String? hint, int maxLines = 1, TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AppTheme.inter(size: 13, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppTheme.card,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.cyan, width: 1.5)),
        ),
      );

  Future<void> _save() async {
    final title = _titleCtr.text.trim();
    final content = _contentCtr.text.trim();
    if (title.isEmpty || content.isEmpty) {
      setState(() => _error = 'Title and content are required.');
      return;
    }
    final youtubeText = _youtubeUrlCtr.text.trim();
    if (youtubeText.isNotEmpty && _youtubeVideoId == null) {
      setState(() => _error = 'Fix or clear the YouTube URL before saving.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final post = Post(
        id: widget.existing?.id ?? '',
        title: title,
        category: _category ?? '',
        content: content,
        imageUrl: _imageUrl,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        contentType: _contentType,
        status: _status,
        contentDepth: _contentDepth,
        deepDiveType: _contentDepth == 'deep' ? _deepDiveType : '',
        youtubeUrl: youtubeText.isEmpty ? null : youtubeText,
        // Saved as false here regardless of the toggle; setFandomOfTheDay
        // below is what actually flips it on, so the "unset every other
        // post" side effect always runs through one code path.
        isFandomOfTheDay: false,
      );

      String postId;
      if (widget.existing == null) {
        postId = await PostService.instance.addPost(post);
      } else {
        postId = post.id;
        await PostService.instance.updatePost(post);
      }

      if (_isFandomOfTheDay) {
        await PostService.instance.setFandomOfTheDay(postId);
      } else if (widget.existing?.isFandomOfTheDay ?? false) {
        await PostService.instance.clearFandomOfTheDay(postId);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Save failed: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Check your connection and try again.';
        });
      }
    }
  }
}
