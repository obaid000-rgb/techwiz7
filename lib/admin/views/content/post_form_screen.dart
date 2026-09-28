import 'package:flutter/material.dart';
import '../../../models/creator.dart';
import '../../../models/fandom.dart';
import '../../../models/post.dart';
import '../../../services/creator_service.dart';
import '../../../services/post_service.dart';
import '../../../services/tag_service.dart';
import '../../../utils/tag_utils.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/youtube_utils.dart';
import '../../widgets/fandom_picker_fields.dart';
import '../../../widgets/image_upload_field.dart';

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
  Fandom? _fandom;
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

  static const int _maxGalleryImages = 12;
  final _audioCtr = TextEditingController();
  final _sourceCtr = TextEditingController();
  final _durationCtr = TextEditingController();
  List<Creator>? _creators;
  String _creatorId = '';
  final List<String> _tags = [];
  final Map<String, String> _tagDisplay = {};
  List<String> _tagSuggestions = const [];
  final List<String> _mediaUrls = [];
  int _galleryUploaderKey = 0;

  Future<void> _loadResourceOptions() async {
    try {
      final creators = await CreatorService.instance.getAllActive();
      final current = widget.existing?.creatorId ?? '';
      if (current.isNotEmpty && !creators.any((c) => c.id == current)) {
        final c = await CreatorService.instance.getById(current);
        if (c != null) creators.add(c);
      }
      if (mounted) setState(() => _creators = creators);
    } catch (e) {
      debugPrint('Creators load failed: $e');
      if (mounted) setState(() => _creators = const []);
    }
    try {
      final tags = await TagService.instance.getAll();
      final posts = await PostService.instance.watchPosts().first;
      final suggestions = <String>{
        for (final t in tags) t.id,
        for (final p in posts) ...normalizeTags(p.tags),
      }.toList()
        ..sort();
      for (final t in tags) {
        _tagDisplay.putIfAbsent(t.id, () => t.name);
      }
      if (mounted) setState(() => _tagSuggestions = suggestions);
    } catch (e) {
      debugPrint('Tag suggestions load failed: $e');
    }
  }

  void _addTag(String raw) {
    final slug = normalizeTag(raw);
    if (slug.isEmpty) return;
    setState(() {
      if (!_tags.contains(slug)) _tags.add(slug);
      _tagDisplay.putIfAbsent(slug, () => raw.trim());
    });
  }

  static int? _parseDuration(String text) {
    final m = RegExp(r'^(\d{1,3}):([0-5]\d)$').firstMatch(text.trim());
    if (m == null) return null;
    return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
  }

  static bool _isHttpsUrl(String text) {
    final uri = Uri.tryParse(text);
    return text.startsWith('https://') && uri != null && uri.host.isNotEmpty;
  }

  static String _formatDuration(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadResourceOptions();
    final e = widget.existing;
    if (e != null) {
      _creatorId = e.creatorId;
      _tags.addAll(normalizeTags(e.tags));
      _mediaUrls.addAll(e.mediaUrls);
      _audioCtr.text = e.audioUrl;
      _sourceCtr.text = e.sourceUrl;
      if (e.durationSeconds > 0) {
        _durationCtr.text = _formatDuration(e.durationSeconds);
      }
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
      _youtubeFieldError = id == null
          ? 'That doesn\'t look like a valid YouTube link.'
          : null;
    });
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _contentCtr.dispose();
    _youtubeUrlCtr.dispose();
    _audioCtr.dispose();
    _sourceCtr.dispose();
    _durationCtr.dispose();
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Lore Post' : 'New Lore Post',
          style: AppTheme.orbitron(size: 13),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.cyan.withValues(alpha: 0.3),
          ),
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
                child: Text(
                  _error!,
                  style: AppTheme.inter(size: 12, color: Colors.redAccent),
                ),
              ),
            _label('Title'),
            _textField(_titleCtr, hint: 'Enter lore post title'),
            const SizedBox(height: 16),
            CategoryFandomPicker(
              initialCategory: _category,
              initialFandomId: (widget.existing?.hasFandom ?? false)
                  ? widget.existing!.fandomId
                  : null,
              accentColor: AppTheme.cyan,
              onCategoryChanged: (v) => setState(() => _category = v),
              onFandomChanged: (f) => setState(() => _fandom = f),
            ),
            const SizedBox(height: 16),
            _label('Content'),
            _textField(
              _contentCtr,
              hint: 'Write the lore content...',
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            _label('Image (optional)'),
            ImageUploadField(
              initialUrl: _imageUrl.isEmpty ? null : _imageUrl,
              onUploaded: (url) => setState(() => _imageUrl = url),
              accentColor: AppTheme.cyan,
            ),
            const SizedBox(height: 16),
            _label(_contentType == 'Video'
                ? 'YouTube URL (required for Video)'
                : 'YouTube URL (optional)'),
            _textField(
              _youtubeUrlCtr,
              hint: 'https://www.youtube.com/watch?v=… or https://youtu.be/…',
            ),
            if (_youtubeFieldError != null) ...[
              const SizedBox(height: 6),
              Text(
                _youtubeFieldError!,
                style: AppTheme.inter(size: 11, color: Colors.redAccent),
              ),
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
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white24,
                          size: 32,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
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
            ..._typeSpecificFields(),
            const SizedBox(height: 16),
            _label('Creator (optional)'),
            _creatorDropdown(),
            const SizedBox(height: 16),
            _label('Tags'),
            _tagInput(),
            const SizedBox(height: 16),
            _label('Status'),
            _dropdown(_status, const [
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
            ], (val) => setState(() => _status = val ?? _status)),
            const SizedBox(height: 16),
            _label('Depth (Beginner / Deep Dive filter)'),
            _dropdown(_contentDepth, const [
              DropdownMenuItem(value: '', child: Text('Unset')),
              DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
              DropdownMenuItem(value: 'deep', child: Text('Deep Dive')),
            ], (val) => setState(() => _contentDepth = val ?? _contentDepth)),
            if (_contentDepth == 'deep') ...[
              const SizedBox(height: 16),
              _label(
                'Deep Dive type (Trivia / Advanced Lore / Interviews tab)',
              ),
              _dropdown(_deepDiveType, [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Unset (All tab only)'),
                ),
                for (final t in kDeepDiveTypes)
                  DropdownMenuItem(
                    value: t,
                    child: Text(kDeepDiveTypeLabels[t]!),
                  ),
              ], (val) => setState(() => _deepDiveType = val ?? _deepDiveType)),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'SAVE POST',
                        style: AppTheme.orbitron(
                          size: 12,
                          color: Colors.black,
                          weight: FontWeight.w800,
                        ),
                      ),
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
  ) => Container(
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

  List<Widget> _typeSpecificFields() {
    switch (_contentType) {
      case 'Video':
        return [
          const SizedBox(height: 16),
          _label('Duration (optional, mm:ss)'),
          _textField(_durationCtr, hint: '12:30'),
        ];
      case 'Podcast':
        return [
          const SizedBox(height: 16),
          _label('Audio URL (required, https://)'),
          _textField(_audioCtr,
              hint: 'https://…/episode.mp3', keyboardType: TextInputType.url),
          const SizedBox(height: 16),
          _label('Duration (optional, mm:ss)'),
          _textField(_durationCtr, hint: '45:00'),
        ];
      case 'News':
        return [
          const SizedBox(height: 16),
          _label('Source URL (optional, https://)'),
          _textField(_sourceCtr,
              hint: 'https://… original article',
              keyboardType: TextInputType.url),
        ];
      case 'Gallery':
        return [
          const SizedBox(height: 16),
          _label('More images (${_mediaUrls.length}/$_maxGalleryImages)'),
          _galleryField(),
        ];
    }
    return const [];
  }

  Widget _galleryField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_mediaUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _mediaUrls.length; i++)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _mediaUrls[i],
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, e, st) => Container(
                              width: 84,
                              height: 84,
                              color: AppTheme.card,
                              child: const Icon(Icons.broken_image_outlined,
                                  color: Colors.white24),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Material(
                            color: Colors.redAccent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () =>
                                  setState(() => _mediaUrls.removeAt(i)),
                              child: const Padding(
                                padding: EdgeInsets.all(3),
                                child: Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          if (_mediaUrls.length < _maxGalleryImages)
            ImageUploadField(
              key: ValueKey('gallery-$_galleryUploaderKey'),
              height: 110,
              accentColor: AppTheme.cyan,
              onUploaded: (url) => setState(() {
                if (_mediaUrls.length < _maxGalleryImages) _mediaUrls.add(url);
                _galleryUploaderKey++;
              }),
            )
          else
            Text('Maximum of $_maxGalleryImages images reached.',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
        ],
      );

  Widget _creatorDropdown() {
    final creators = _creators;
    if (creators == null) {
      return _dropdown('', const [
        DropdownMenuItem(value: '', child: Text('Loading creators…')),
      ], (_) {});
    }
    final value = creators.any((c) => c.id == _creatorId) ? _creatorId : '';
    return _dropdown(value, [
      const DropdownMenuItem(value: '', child: Text('None')),
      for (final c in creators)
        DropdownMenuItem(
          value: c.id,
          child: Text(c.isActive ? c.name : '${c.name} (inactive)',
              overflow: TextOverflow.ellipsis),
        ),
    ], (v) => setState(() => _creatorId = v ?? ''));
  }

  Widget _tagInput() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in _tags)
                    InputChip(
                      label: Text('#$t',
                          style: AppTheme.inter(size: 11, color: Colors.white)),
                      backgroundColor: AppTheme.card,
                      side: BorderSide(
                          color: AppTheme.cyan.withValues(alpha: 0.5)),
                      deleteIconColor: Colors.grey,
                      onDeleted: () => setState(() => _tags.remove(t)),
                    ),
                ],
              ),
            ),
          Autocomplete<String>(
            optionsBuilder: (value) {
              final q = normalizeTag(value.text);
              if (q.isEmpty) return const Iterable<String>.empty();
              return _tagSuggestions
                  .where((s) => s.contains(q) && !_tags.contains(s))
                  .take(8);
            },
            displayStringForOption: (s) => '#$s',
            onSelected: (s) => _addTag(_tagDisplay[s] ?? s),
            fieldViewBuilder: (context, ctrl, focus, onSubmit) => TextField(
              controller: ctrl,
              focusNode: focus,
              style: AppTheme.inter(size: 13, color: Colors.white),
              textInputAction: TextInputAction.done,
              onChanged: (v) {
                if (v.contains(',')) {
                  for (final part in v.split(',')) {
                    _addTag(part);
                  }
                  ctrl.clear();
                }
              },
              onSubmitted: (v) {
                _addTag(v);
                ctrl.clear();
                focus.requestFocus();
              },
              decoration: InputDecoration(
                hintText: 'Type a tag and press enter, e.g. trailer',
                filled: true,
                fillColor: AppTheme.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cyan, width: 1.5),
                ),
              ),
            ),
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: AppTheme.card,
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 240, maxWidth: 360),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      for (final o in options)
                        ListTile(
                          dense: true,
                          title: Text('#$o',
                              style: AppTheme.inter(
                                  size: 13, color: Colors.white)),
                          onTap: () => onSelected(o),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
              Text(
                'Today\'s Fandom',
                style: AppTheme.inter(
                  size: 13,
                  color: Colors.white,
                  weight: FontWeight.w600,
                ),
              ),
              Text(
                'Featured as the single highlight on the Lore tab',
                style: AppTheme.inter(size: 10, color: Colors.grey),
              ),
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
    child: Text(text, style: AppTheme.inter(size: 12, color: Colors.grey)),
  );

  Widget _textField(
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => TextField(
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
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.cyan, width: 1.5),
      ),
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
    if (_contentType == 'Video' && youtubeText.isEmpty) {
      setState(() => _error = 'A YouTube URL is required for Video posts.');
      return;
    }
    final audio = _audioCtr.text.trim();
    if (_contentType == 'Podcast') {
      if (audio.isEmpty) {
        setState(() => _error = 'An audio URL is required for Podcast posts.');
        return;
      }
      if (!_isHttpsUrl(audio)) {
        setState(() => _error = 'The audio URL must start with https://');
        return;
      }
    }
    final source = _sourceCtr.text.trim();
    if (_contentType == 'News' && source.isNotEmpty && !_isHttpsUrl(source)) {
      setState(() => _error = 'The source URL must start with https://');
      return;
    }
    final hasDuration = _contentType == 'Video' || _contentType == 'Podcast';
    final durationText = _durationCtr.text.trim();
    final duration = durationText.isEmpty ? 0 : _parseDuration(durationText);
    if (hasDuration && duration == null) {
      setState(() => _error = 'Enter the duration as mm:ss, for example 12:30.');
      return;
    }
    final existing = widget.existing;
    final fandomRequired = existing == null || existing.hasFandom;
    final fandom = _fandom;
    if (fandomRequired && fandom == null) {
      setState(
        () => _error = _category == null
            ? 'Choose a category and a fandom for this post.'
            : 'Choose a fandom for this post.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final tags = normalizeTags(_tags);
      final creator = _creatorId.isEmpty
          ? null
          : (_creators ?? const <Creator>[])
              .where((c) => c.id == _creatorId)
              .firstOrNull;
      final post = Post(
        id: widget.existing?.id ?? '',
        title: title,
        category: fandom?.categoryId ?? _category ?? '',
        fandomId: fandom?.id ?? '',
        fandomName: fandom?.name ?? '',
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
        tags: tags,
        creatorId: creator?.id ??
            (_creatorId.isNotEmpty && _creatorId == existing?.creatorId
                ? existing!.creatorId
                : ''),
        creatorName: creator?.name ??
            (_creatorId.isNotEmpty && _creatorId == existing?.creatorId
                ? existing!.creatorName
                : ''),
        mediaUrls:
            _contentType == 'Gallery' ? List.of(_mediaUrls) : const [],
        audioUrl: _contentType == 'Podcast' ? audio : '',
        sourceUrl: _contentType == 'News' ? source : '',
        durationSeconds: hasDuration ? (duration ?? 0) : 0,
      );

      final newTags = await TagService.instance.missing({
        for (final t in tags) t: (_tagDisplay[t]?.trim().isNotEmpty ?? false)
            ? _tagDisplay[t]!.trim()
            : t,
      });
      final postId = await PostService.instance.savePostWithTags(
        post,
        newTags,
        isNew: widget.existing == null,
      );

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
