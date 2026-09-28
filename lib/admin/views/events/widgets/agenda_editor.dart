import 'package:flutter/material.dart';
import '../../../../logic/event_status.dart';
import '../../../../models/event_session.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/event_format.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Date picker then time picker. [first] and [last] bound the date; the
/// result is null when either picker is dismissed.
Future<DateTime?> pickEventDateTime(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
  Color accent = AppTheme.pink,
}) async {
  Widget themed(BuildContext ctx, Widget? child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(primary: accent, surface: AppTheme.card),
        ),
        child: child!,
      );
  final firstDay = _day(first);
  final lastDay = _day(last);
  var initialDay = _day(initial);
  if (initialDay.isBefore(firstDay)) initialDay = firstDay;
  if (initialDay.isAfter(lastDay)) initialDay = lastDay;
  final date = await showDatePicker(
    context: context,
    initialDate: initialDay,
    firstDate: firstDay,
    lastDate: lastDay,
    builder: themed,
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
    builder: themed,
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// A tappable "Oct 14, 10:00 AM" field that opens [pickEventDateTime].
class DateTimeField extends StatelessWidget {
  final DateTime value;
  final VoidCallback onTap;
  final bool hasError;
  const DateTimeField({super.key, required this.value, required this.onTap, this.hasError = false});

  @override
  Widget build(BuildContext context) => Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hasError ? Colors.redAccent : AppTheme.border),
            ),
            child: Row(children: [
              const Icon(Icons.schedule, color: AppTheme.pink, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${formatEventDay(value)} · ${formatEventTime(value)}',
                    style: AppTheme.inter(size: 13, color: Colors.white)),
              ),
            ]),
          ),
        ),
      );
}

/// Agenda editor for the admin event form: the event's sessions sorted by
/// start time, each editable or removable, plus "Add session". Sessions
/// with a problem (from the form's validation) show it in red.
class AgendaEditor extends StatelessWidget {
  final List<EventSession> sessions;
  final DateTime eventStart;
  /// The event's effective end (its end time, or the end of the start day).
  final DateTime eventEnd;
  final Map<String, String> errors;
  final ValueChanged<List<EventSession>> onChanged;

  const AgendaEditor({
    super.key,
    required this.sessions,
    required this.eventStart,
    required this.eventEnd,
    required this.onChanged,
    this.errors = const {},
  });

  Future<void> _edit(BuildContext context, [EventSession? existing]) async {
    final result = await showDialog<EventSession>(
      context: context,
      builder: (_) => SessionEditorDialog(
        existing: existing,
        eventStart: eventStart,
        eventEnd: eventEnd,
      ),
    );
    if (result == null) return;
    onChanged(sortSessions([
      for (final s in sessions)
        if (s.id != result.id) s,
      result,
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final sorted = sortSessions(sessions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('No sessions yet. The agenda is optional.',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
          ),
        for (final s in sorted) _row(context, s),
        OutlinedButton.icon(
          onPressed: () => _edit(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.pink),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.add, color: AppTheme.pink, size: 16),
          label: Text('Add session', style: AppTheme.inter(size: 12, color: AppTheme.pink)),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, EventSession s) {
    final error = errors[s.id];
    final sameDay = _day(s.startAt) == _day(s.endAt);
    final when = sameDay
        ? '${formatEventDay(s.startAt)} · ${formatEventTime(s.startAt)} to ${formatEventTime(s.endAt)}'
        : '${formatEventDateTime(s.startAt)} to ${formatEventDateTime(s.endAt)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: error != null ? Colors.redAccent : AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(size: 13, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(s.stage.isEmpty ? when : '$when · ${s.stage}',
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Text(error, style: AppTheme.inter(size: 11, color: Colors.redAccent)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.cyan, size: 17),
            tooltip: 'Edit session',
            onPressed: () => _edit(context, s),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 17),
            tooltip: 'Remove session',
            onPressed: () => onChanged([
              for (final x in sessions)
                if (x.id != s.id) x,
            ]),
          ),
        ],
      ),
    );
  }
}

/// Add/edit one session. Its date pickers only offer the event's days, and
/// Save is refused (with the reason shown) until [validateSession] passes.
class SessionEditorDialog extends StatefulWidget {
  final EventSession? existing;
  final DateTime eventStart;
  final DateTime eventEnd;
  const SessionEditorDialog({
    super.key,
    this.existing,
    required this.eventStart,
    required this.eventEnd,
  });

  @override
  State<SessionEditorDialog> createState() => _SessionEditorDialogState();
}

class _SessionEditorDialogState extends State<SessionEditorDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _stage =
      TextEditingController(text: widget.existing?.stage ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late DateTime _start = widget.existing?.startAt ?? widget.eventStart;
  late DateTime _end = widget.existing?.endAt ?? _defaultEnd(widget.eventStart);
  String? _error;

  DateTime _defaultEnd(DateTime start) {
    final hourLater = start.add(const Duration(hours: 1));
    return hourLater.isAfter(widget.eventEnd) ? widget.eventEnd : hourLater;
  }

  // Last selectable day: the event's end, less a moment so an end at
  // midnight doesn't offer the following day.
  DateTime get _lastDay => widget.eventEnd.subtract(const Duration(microseconds: 1));

  @override
  void dispose() {
    _title.dispose();
    _stage.dispose();
    _description.dispose();
    super.dispose();
  }

  EventSession get _draft => EventSession(
        id: widget.existing?.id ?? '${DateTime.now().microsecondsSinceEpoch}',
        title: _title.text.trim(),
        startAt: _start,
        endAt: _end,
        stage: _stage.text.trim(),
        description: _description.text.trim(),
      );

  Future<void> _pick({required bool start}) async {
    final picked = await pickEventDateTime(
      context,
      initial: start ? _start : _end,
      first: widget.eventStart,
      last: _lastDay,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        final length = _end.difference(_start);
        _start = picked;
        if (!length.isNegative) _end = picked.add(length);
      } else {
        _end = picked;
      }
      if (_error != null) _error = validateSession(_draft, widget.eventStart, widget.eventEnd);
    });
  }

  void _save() {
    final draft = _draft;
    final error = validateSession(draft, widget.eventStart, widget.eventEnd);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, draft);
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTheme.inter(size: 12, color: Colors.grey),
        filled: true,
        fillColor: AppTheme.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.pink, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    final label = AppTheme.inter(size: 12, color: Colors.grey);
    return AlertDialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.existing == null ? 'Add session' : 'Edit session',
          style: AppTheme.orbitron(size: 13)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                style: AppTheme.inter(size: 13, color: Colors.white),
                decoration: _decoration('Title'),
              ),
              const SizedBox(height: 12),
              Text('Starts', style: label),
              const SizedBox(height: 4),
              DateTimeField(value: _start, onTap: () => _pick(start: true)),
              const SizedBox(height: 10),
              Text('Ends', style: label),
              const SizedBox(height: 4),
              DateTimeField(
                  value: _end, hasError: _error != null, onTap: () => _pick(start: false)),
              const SizedBox(height: 6),
              Text('Event runs ${formatEventDateTime(widget.eventStart)} to '
                  '${formatEventDateTime(widget.eventEnd)}',
                  style: AppTheme.inter(size: 10, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: _stage,
                style: AppTheme.inter(size: 13, color: Colors.white),
                decoration: _decoration('Stage (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                style: AppTheme.inter(size: 13, color: Colors.white),
                decoration: _decoration('Description (optional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: AppTheme.inter(size: 12, color: Colors.redAccent)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: AppTheme.inter(size: 12, color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pink),
          child: Text('SAVE SESSION',
              style: AppTheme.inter(size: 12, color: Colors.white, weight: FontWeight.w700)),
        ),
      ],
    );
  }
}
