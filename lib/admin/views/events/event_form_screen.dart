import 'package:flutter/material.dart';
import '../../../logic/event_status.dart';
import '../../../models/event_item.dart';
import '../../../models/event_session.dart';
import '../../../models/event_type.dart';
import '../../../services/event_service.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/fandom_picker_fields.dart';
import '../../../widgets/image_upload_field.dart';
import 'widgets/agenda_editor.dart';
import 'widgets/location_picker_field.dart';

class EventFormScreen extends StatefulWidget {
  final EventItem? existing;
  const EventFormScreen({super.key, this.existing});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _titleCtr = TextEditingController();
  final _cityCtr = TextEditingController();
  final _venueCtr = TextEditingController();
  final _addressCtr = TextEditingController();
  final _organizerCtr = TextEditingController();
  final _linkCtr = TextEditingController();
  final _priceCtr = TextEditingController();
  EventType _type = EventType.other;
  late DateTime _start;
  DateTime? _endAt;
  List<EventSession> _sessions = [];
  String _imageUrl = '';
  String? _category;
  List<String> _fandomIds = [];
  double? _latitude;
  double? _longitude;
  bool _isTrendingOnHome = false;
  bool _saving = false;
  bool _imageBusy = false;
  String? _error;
  // After the first save attempt, field errors update live as they're fixed.
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtr.text = e.title;
      _cityCtr.text = e.city;
      _venueCtr.text = e.venue;
      _addressCtr.text = e.address;
      _organizerCtr.text = e.organizerName;
      _linkCtr.text = e.ticketLink;
      _priceCtr.text = e.ticketPrice;
      _type = e.eventType;
      _start = e.date;
      _endAt = e.endAt;
      _sessions = List.of(e.sessions);
      _imageUrl = e.imageUrl;
      _category = e.category.isEmpty ? null : e.category;
      _latitude = e.latitude;
      _longitude = e.longitude;
      _isTrendingOnHome = e.isTrendingOnHome;
      _fandomIds = List.of(e.fandomIds);
    } else {
      final now = DateTime.now();
      _start = DateTime(now.year, now.month, now.day + 1, 10);
    }
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _cityCtr.dispose();
    _venueCtr.dispose();
    _addressCtr.dispose();
    _organizerCtr.dispose();
    _linkCtr.dispose();
    _priceCtr.dispose();
    super.dispose();
  }

  // Date pickers start at today (past days are greyed out) and run three
  // years ahead; a past time on today is refused with a message.
  DateTime get _firstDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _lastDate {
    final now = DateTime.now();
    return DateTime(now.year + 3, now.month, now.day);
  }

  static const _pastMessage = 'You cannot select a previous date or time.';

  bool _notPast(DateTime? picked) {
    if (picked == null) return false;
    if (picked.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(_pastMessage)));
      return false;
    }
    return true;
  }

  EventItem _draft() {
    final existing = widget.existing;
    return EventItem(
      id: existing?.id ?? '',
      title: _titleCtr.text.trim(),
      city: _cityCtr.text.trim(),
      date: _start,
      venue: _venueCtr.text.trim(),
      ticketLink: _linkCtr.text.trim(),
      ticketPrice: _priceCtr.text.trim(),
      imageUrl: _imageUrl,
      category: _category ?? '',
      latitude: _latitude,
      longitude: _longitude,
      isTrendingOnHome: _isTrendingOnHome,
      fandomIds: _fandomIds,
      type: _type.key,
      endAt: _endAt,
      address: _addressCtr.text.trim(),
      organizerName: _organizerCtr.text.trim(),
      sessions: sortSessions(_sessions),
      isPublished: existing?.isPublished ?? true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final validation = _showErrors ? validateEvent(_draft()) : const EventValidation();
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
        title: Text(isEdit ? 'Edit Event' : 'New Event',
            style: AppTheme.orbitron(size: 13)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: AppTheme.pink.withValues(alpha: 0.3)),
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
            _label('Event Title'),
            _textField(_titleCtr, hint: 'Convention / concert name'),
            const SizedBox(height: 16),
            _label('Event Type'),
            _typeDropdown(),
            const SizedBox(height: 16),
            FandomMultiPicker(
              initialIds: _fandomIds,
              accentColor: AppTheme.pink,
              onChanged: (ids) => setState(() => _fandomIds = ids),
            ),
            const SizedBox(height: 16),
            _label('Location (tap map to place a pin)'),
            LocationPickerField(
              initialLat: _latitude,
              initialLng: _longitude,
              onLocationPicked: (lat, lng, city, address) {
                setState(() {
                  _latitude = lat;
                  _longitude = lng;
                  if (city != null && city.isNotEmpty) _cityCtr.text = city;
                  // Prefill only an empty address; a typed one is kept.
                  if (address != null && _addressCtr.text.trim().isEmpty) {
                    _addressCtr.text = address;
                  }
                });
              },
            ),
            if (validation.location != null) _errorText(validation.location!),
            const SizedBox(height: 16),
            _label('City'),
            _textField(_cityCtr, hint: 'Tokyo, London, New York…'),
            const SizedBox(height: 16),
            _label('Starts'),
            DateTimeField(
              value: _start,
              onTap: () async {
                final picked = await pickEventDateTime(context,
                    initial: _start, first: _firstDate, last: _lastDate);
                if (!_notPast(picked)) return;
                setState(() {
                  final end = _endAt;
                  // Keep end > start: a start at/after the end pushes the
                  // end forward by the old duration (or clears it).
                  if (end != null && !end.isAfter(picked!)) {
                    final duration = end.difference(_start);
                    _endAt = duration > Duration.zero
                        ? picked.add(duration)
                        : null;
                  }
                  _start = picked!;
                });
              },
            ),
            const SizedBox(height: 16),
            _label('Ends (optional)'),
            _endField(validation.end != null),
            if (validation.end != null) _errorText(validation.end!),
            const SizedBox(height: 16),
            _label('Venue name'),
            _textField(_venueCtr, hint: 'Venue or arena name'),
            const SizedBox(height: 16),
            _label('Address (optional, filled from the map pin)'),
            _textField(_addressCtr, hint: 'Street, area, city', maxLines: 2),
            const SizedBox(height: 16),
            _label('Organizer (optional)'),
            _textField(_organizerCtr, hint: 'Who runs the event'),
            const SizedBox(height: 16),
            _label('Ticket Link (optional)'),
            _textField(_linkCtr,
                hint: 'https://tickets.example.com',
                keyboardType: TextInputType.url,
                errorText: validation.ticketLink),
            const SizedBox(height: 16),
            _label('Price (optional)'),
            _textField(_priceCtr, hint: 'Free, PKR 1,500, \$25.00'),
            const SizedBox(height: 16),
            _label('Agenda (optional)'),
            AgendaEditor(
              sessions: _sessions,
              eventStart: _start,
              eventEnd: endFor(_start, _endAt),
              errors: validation.sessions,
              onChanged: (list) => setState(() => _sessions = list),
            ),
            const SizedBox(height: 16),
            _label('Event Image (optional)'),
            ImageUploadField(
              initialUrl: _imageUrl.isEmpty ? null : _imageUrl,
              onUploaded: (url) => setState(() => _imageUrl = url),
              onBusyChanged: (busy) {
                if (mounted) setState(() => _imageBusy = busy);
              },
              accentColor: AppTheme.pink,
            ),
            if (_imageBusy)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Wait for the image to finish uploading',
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.pink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.pink.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_outlined, color: AppTheme.pink, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trending on Home',
                            style: AppTheme.inter(
                                size: 13, color: Colors.white, weight: FontWeight.w600)),
                        Text('Shows this event in Trending Events on Home (until it ends)',
                            style: AppTheme.inter(size: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isTrendingOnHome,
                    activeThumbColor: AppTheme.pink,
                    onChanged: (val) => setState(() => _isTrendingOnHome = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving || _imageBusy ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('SAVE EVENT',
                        style: AppTheme.orbitron(
                            size: 12,
                            color: Colors.white,
                            weight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: AppTheme.inter(size: 12, color: Colors.grey)),
      );

  Widget _errorText(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text, style: AppTheme.inter(size: 11, color: Colors.redAccent)),
      );

  Widget _textField(TextEditingController ctrl,
          {String? hint, TextInputType? keyboardType, String? errorText, int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: 1,
        onChanged: _showErrors ? (_) => setState(() {}) : null,
        style: AppTheme.inter(size: 13, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          errorText: errorText,
          errorMaxLines: 2,
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
                  const BorderSide(color: AppTheme.pink, width: 1.5)),
        ),
      );

  Widget _typeDropdown() => DropdownButtonFormField<EventType>(
        initialValue: _type,
        dropdownColor: AppTheme.card,
        style: AppTheme.inter(size: 13, color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border)),
        ),
        items: [
          for (final t in EventType.values)
            DropdownMenuItem(
              value: t,
              child: Row(children: [
                Icon(t.icon, color: t.color, size: 18),
                const SizedBox(width: 10),
                Text(t == EventType.other ? 'Other' : t.label),
              ]),
            ),
        ],
        onChanged: (t) => setState(() => _type = t ?? EventType.other),
      );

  Widget _endField(bool hasError) {
    final end = _endAt;
    Future<void> pick() async {
      final picked = await pickEventDateTime(context,
          initial: end ?? _start.add(const Duration(hours: 8)),
          first: _firstDate,
          last: _lastDate);
      if (_notPast(picked)) setState(() => _endAt = picked!);
    }

    if (end == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: pick,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.pink),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, color: AppTheme.pink, size: 16),
            label: Text('Add end time', style: AppTheme.inter(size: 12, color: AppTheme.pink)),
          ),
          const SizedBox(height: 4),
          Text('No end time: the event ends at the end of its start day.',
              style: AppTheme.inter(size: 10, color: Colors.grey)),
        ],
      );
    }
    return Row(children: [
      Expanded(child: DateTimeField(value: end, hasError: hasError, onTap: pick)),
      IconButton(
        icon: const Icon(Icons.close, color: Colors.grey, size: 18),
        tooltip: 'Remove end time',
        onPressed: () => setState(() => _endAt = null),
      ),
    ]);
  }

  Future<void> _save() async {
    if (_imageBusy) {
      setState(() => _error = 'Wait for the image to finish uploading.');
      return;
    }
    final event = _draft();
    final validation = validateEvent(event);
    final missing = event.title.isEmpty || event.city.isEmpty || event.venue.isEmpty;
    if (missing || !validation.isValid) {
      setState(() {
        _showErrors = true;
        _error = missing
            ? 'Title, city and venue name are required.'
            : 'Fix the fields marked in red before saving.';
      });
      return;
    }
    // A new event, or a changed start/end, can't be in the past. An event
    // that is already running can still be edited without touching them.
    final existing = widget.existing;
    final timingError = validateEventTiming(
      start: event.date,
      end: event.endAt,
      now: DateTime.now(),
      isNew: existing == null,
      previousStart: existing?.date,
      previousEnd: existing?.endAt,
    );
    if (timingError != null) {
      setState(() => _error = timingError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.existing == null) {
        await EventService.instance.addEvent(event);
      } else {
        await EventService.instance.updateEvent(event);
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
