import 'package:flutter/material.dart';
import '../../models/event_item.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_picker_field.dart';
import '../../widgets/image_upload_field.dart';
import '../../widgets/location_picker_field.dart';

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
  final _linkCtr = TextEditingController();
  final _priceCtr = TextEditingController();
  DateTime _date = DateTime.now();
  String _imageUrl = '';
  String? _category;
  double? _latitude;
  double? _longitude;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtr.text = e.title;
      _cityCtr.text = e.city;
      _venueCtr.text = e.venue;
      _linkCtr.text = e.ticketLink;
      _priceCtr.text = e.ticketPrice;
      _date = e.date;
      _imageUrl = e.imageUrl;
      _category = e.category.isEmpty ? null : e.category;
      _latitude = e.latitude;
      _longitude = e.longitude;
    }
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _cityCtr.dispose();
    _venueCtr.dispose();
    _linkCtr.dispose();
    _priceCtr.dispose();
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
            _label('Category'),
            CategoryPickerField(
              value: _category,
              accentColor: AppTheme.pink,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),
            _label('Location (tap map to place a pin)'),
            LocationPickerField(
              initialLat: _latitude,
              initialLng: _longitude,
              onLocationPicked: (lat, lng, city) {
                setState(() {
                  _latitude = lat;
                  _longitude = lng;
                  if (city != null && city.isNotEmpty) _cityCtr.text = city;
                });
              },
            ),
            const SizedBox(height: 16),
            _label('City'),
            _textField(_cityCtr, hint: 'Tokyo, London, New York…'),
            const SizedBox(height: 16),
            _label('Date'),
            _datePicker(context),
            const SizedBox(height: 16),
            _label('Venue'),
            _textField(_venueCtr, hint: 'Venue or arena name'),
            const SizedBox(height: 16),
            _label('Ticket Link (optional)'),
            _textField(_linkCtr,
                hint: 'https://tickets.example.com',
                keyboardType: TextInputType.url),
            const SizedBox(height: 16),
            _label('Ticket Price (optional)'),
            _textField(_priceCtr, hint: '\$25.00 or Free'),
            const SizedBox(height: 16),
            _label('Event Image (optional)'),
            ImageUploadField(
              initialUrl: _imageUrl.isEmpty ? null : _imageUrl,
              onUploaded: (url) => setState(() => _imageUrl = url),
              accentColor: AppTheme.pink,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
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

  Widget _textField(TextEditingController ctrl,
          {String? hint, TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
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
                  const BorderSide(color: AppTheme.pink, width: 1.5)),
        ),
      );

  Widget _datePicker(BuildContext context) => GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.pink,
                  surface: AppTheme.card,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) setState(() => _date = picked);
        },
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: AppTheme.pink, size: 16),
              const SizedBox(width: 10),
              Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                style: AppTheme.inter(size: 13, color: Colors.white),
              ),
            ],
          ),
        ),
      );

  Future<void> _save() async {
    final title = _titleCtr.text.trim();
    final city = _cityCtr.text.trim();
    final venue = _venueCtr.text.trim();
    if (title.isEmpty || city.isEmpty || venue.isEmpty) {
      setState(() => _error = 'Title, city and venue are required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final event = EventItem(
        id: widget.existing?.id ?? '',
        title: title,
        city: city,
        date: _date,
        venue: venue,
        ticketLink: _linkCtr.text.trim(),
        ticketPrice: _priceCtr.text.trim(),
        imageUrl: _imageUrl,
        category: _category ?? '',
        latitude: _latitude,
        longitude: _longitude,
      );
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
