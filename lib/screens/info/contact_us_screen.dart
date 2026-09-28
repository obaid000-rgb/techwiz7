import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_info.dart';
import '../../models/faq.dart';
import '../../services/auth_service.dart';
import '../../services/faq_service.dart';
import '../../services/inquiry_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import 'widgets/info_ui.dart';

enum _FormState { editing, sending, sent, queued }

/// Contact Us: inquiry form (saved to Firestore), contact details and the
/// office location. Organisation details come from [AppInfo]; anything not
/// set there shows as "coming soon" rather than invented data.
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoPageScaffold(
      title: 'Contact Us',
      children: [
        FadeSlideIn(
          child: Column(children: [
            const SizedBox(height: 6),
            const GlowIcon(Icons.forum_outlined, size: 64),
            const SizedBox(height: 16),
            Text('Get in touch',
                textAlign: TextAlign.center,
                style: AppTheme.orbitron(size: 22, weight: FontWeight.w800, color: InfoColors.lavender)),
            const SizedBox(height: 8),
            Text('Questions, feedback or partnership ideas — send us a message and the team will get back to you.',
                textAlign: TextAlign.center,
                style: AppTheme.inter(size: 14, color: AppTheme.textSecondary, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 30),
        const _FaqSection(),
        const FadeSlideIn(
          delay: Duration(milliseconds: 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InfoSectionHeading(eyebrow: 'WRITE TO US', title: 'Send an Inquiry'),
            _InquiryForm(),
          ]),
        ),
        const SizedBox(height: 32),
        const FadeSlideIn(
          delay: Duration(milliseconds: 220),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InfoSectionHeading(eyebrow: 'REACH US', title: 'Contact Details'),
            _ContactDetails(),
          ]),
        ),
        const SizedBox(height: 32),
        const FadeSlideIn(
          delay: Duration(milliseconds: 320),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InfoSectionHeading(eyebrow: 'FIND US', title: 'Office Location'),
            _OfficeLocation(),
          ]),
        ),
      ],
    );
  }
}

// ── Send an Inquiry ──────────────────────────────────────────────────────────

class _InquiryForm extends StatefulWidget {
  const _InquiryForm();

  @override
  State<_InquiryForm> createState() => _InquiryFormState();
}

class _InquiryFormState extends State<_InquiryForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: AuthService.instance.currentUser?.name ?? '');
  late final _email = TextEditingController(text: AuthService.instance.currentUser?.email ?? '');
  final _subject = TextEditingController();
  final _message = TextEditingController();
  _FormState _state = _FormState.editing;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _state = _FormState.sending;
      _error = null;
    });
    try {
      final result = await InquiryService.instance.submit(
        name: _name.text.trim(),
        email: _email.text.trim(),
        subject: _subject.text.trim(),
        message: _message.text.trim(),
      );
      if (!mounted) return;
      setState(() => _state = result == InquiryResult.sent ? _FormState.sent : _FormState.queued);
    } catch (e) {
      debugPrint('Inquiry send failed: $e');
      if (!mounted) return;
      setState(() {
        _state = _FormState.editing;
        _error = "Couldn't send your message. Check your connection and try again.";
      });
    }
  }

  void _reset() {
    _subject.clear();
    _message.clear();
    setState(() => _state = _FormState.editing);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _state == _FormState.sent || _state == _FormState.queued
            ? _success(key: const ValueKey('done'))
            : _form(key: const ValueKey('form')),
      ),
    );
  }

  Widget _form({Key? key}) {
    final sending = _state == _FormState.sending;
    return Form(
      key: _formKey,
      child: AbsorbPointer(
        key: key,
        absorbing: sending,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _field(
            controller: _name,
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            action: TextInputAction.next,
            maxLength: 60,
            capitalization: TextCapitalization.words,
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'Please enter your name';
              if (t.length < 2) return 'Name is too short';
              return null;
            },
          ),
          _field(
            controller: _email,
            label: 'Email',
            icon: Icons.alternate_email_rounded,
            action: TextInputAction.next,
            keyboard: TextInputType.emailAddress,
            maxLength: 100,
            validator: Validators.validateEmail,
          ),
          _field(
            controller: _subject,
            label: 'Subject',
            icon: Icons.short_text_rounded,
            action: TextInputAction.next,
            maxLength: 100,
            capitalization: TextCapitalization.sentences,
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'Please add a subject';
              if (t.length < 3) return 'Subject is too short';
              return null;
            },
          ),
          _field(
            controller: _message,
            label: 'Message',
            icon: Icons.chat_bubble_outline_rounded,
            maxLines: 5,
            maxLength: 1000,
            capitalization: TextCapitalization.sentences,
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'Please write your message';
              if (t.length < 10) return 'Please write at least 10 characters';
              return null;
            },
          ),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(_error!, style: AppTheme.inter(size: 12, color: Colors.redAccent))),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 4),
          GradientButton(
            label: 'SEND MESSAGE',
            icon: Icons.send_rounded,
            loading: sending,
            onPressed: _send,
          ),
        ]),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputAction? action,
    TextInputType? keyboard,
    int maxLines = 1,
    int? maxLength,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        textInputAction: action,
        keyboardType: maxLines > 1 ? TextInputType.multiline : keyboard,
        textCapitalization: capitalization,
        maxLines: maxLines,
        minLines: maxLines > 1 ? 4 : 1,
        maxLength: maxLength,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: AppTheme.inter(size: 14, color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTheme.inter(size: 13, color: AppTheme.textMuted),
          floatingLabelStyle: AppTheme.inter(size: 13, color: InfoColors.lavender),
          alignLabelWithHint: maxLines > 1,
          prefixIcon: maxLines > 1
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 70),
                  child: Icon(icon, color: AppTheme.accent, size: 20),
                )
              : Icon(icon, color: AppTheme.accent, size: 20),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.04),
          counterStyle: AppTheme.inter(size: 10, color: AppTheme.textMuted),
          errorStyle: AppTheme.inter(size: 11, color: Colors.redAccent),
          enabledBorder: border(InfoColors.glassBorder),
          focusedBorder: border(AppTheme.accent, 1.5),
          errorBorder: border(Colors.redAccent.withValues(alpha: 0.7)),
          focusedErrorBorder: border(Colors.redAccent, 1.5),
        ),
      ),
    );
  }

  Widget _success({Key? key}) {
    final queued = _state == _FormState.queued;
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        GlowIcon(queued ? Icons.schedule_send_rounded : Icons.check_rounded, size: 64),
        const SizedBox(height: 18),
        Text(queued ? 'Message saved' : 'Message sent!',
            style: AppTheme.orbitron(size: 18, weight: FontWeight.w800, color: InfoColors.lavender)),
        const SizedBox(height: 8),
        Text(
          queued
              ? "You're offline right now. Your message is saved on this device and will be sent automatically when you're back online — no need to send it again."
              : 'Thanks for reaching out. The team will reply to ${_email.text.trim()}.',
          textAlign: TextAlign.center,
          style: AppTheme.inter(size: 14, color: AppTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 22),
        GlowOutlineButton(label: 'Send another message', icon: Icons.edit_outlined, onPressed: _reset),
      ]),
    );
  }
}

// ── Contact Details ──────────────────────────────────────────────────────────

class _ContactDetails extends StatelessWidget {
  const _ContactDetails();

  @override
  Widget build(BuildContext context) {
    const email = AppInfo.supportEmail;
    const phone = AppInfo.phone;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(children: [
        _row(context, Icons.groups_2_outlined, 'Team', AppInfo.teamName),
        _divider(),
        _row(context, Icons.mail_outline_rounded, 'Email', email,
            onTap: email == null
                ? null
                : () => openExternal(context, Uri(scheme: 'mailto', path: email),
                    'No email app found to send to $email.')),
        _divider(),
        _row(context, Icons.phone_outlined, 'Phone', phone,
            onTap: phone == null
                ? null
                : () => openExternal(context, Uri(scheme: 'tel', path: phone.replaceAll(' ', '')),
                    'Could not start a call on this device.')),
        _divider(),
        _row(context, Icons.schedule_rounded, 'Working hours', AppInfo.workingHours),
      ]),
    );
  }

  Widget _divider() => const Divider(height: 1, color: InfoColors.glassBorder);

  Widget _row(BuildContext context, IconData icon, String label, String? value, {VoidCallback? onTap}) {
    final missing = value == null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          GlowIcon(icon, size: 40, muted: missing),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label.toUpperCase(),
                  style: AppTheme.inter(size: 10, weight: FontWeight.w700, color: AppTheme.textMuted)
                      .copyWith(letterSpacing: 1.5)),
              const SizedBox(height: 3),
              Text(value ?? 'Coming soon',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: missing
                      ? AppTheme.inter(size: 14, color: AppTheme.textMuted).copyWith(fontStyle: FontStyle.italic)
                      : AppTheme.inter(size: 14, weight: FontWeight.w600, color: InfoColors.lavender)),
            ]),
          ),
          if (onTap != null) const Icon(Icons.north_east_rounded, color: AppTheme.accent, size: 18),
        ]),
      ),
    );
  }
}

// ── Office Location ──────────────────────────────────────────────────────────

class _OfficeLocation extends StatelessWidget {
  const _OfficeLocation();

  /// Google Maps link target: exact coordinates when known, else the address.
  static String? get _query {
    if (AppInfo.hasOfficeCoordinates) return '${AppInfo.officeLatitude},${AppInfo.officeLongitude}';
    return AppInfo.officeAddress;
  }

  @override
  Widget build(BuildContext context) {
    final query = _query;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(height: 210, child: AppInfo.hasOfficeCoordinates ? _map() : _mapPlaceholder()),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GlowIcon(Icons.location_on_outlined, size: 40, muted: !AppInfo.hasOfficeLocation),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('OFFICE ADDRESS',
                      style: AppTheme.inter(size: 10, weight: FontWeight.w700, color: AppTheme.textMuted)
                          .copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 3),
                  Text(
                    AppInfo.officeAddress ?? (AppInfo.hasOfficeLocation ? 'See map' : 'Coming soon'),
                    style: AppInfo.officeAddress == null
                        ? AppTheme.inter(size: 14, color: AppTheme.textMuted).copyWith(fontStyle: FontStyle.italic)
                        : AppTheme.inter(size: 14, weight: FontWeight.w600, color: InfoColors.lavender, height: 1.4),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              GlowOutlineButton(
                label: 'Open in Google Maps',
                icon: Icons.map_outlined,
                onPressed: query == null
                    ? null
                    : () => openExternal(
                          context,
                          Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query}),
                          'Could not open Google Maps.',
                        ),
              ),
              GlowOutlineButton(
                label: 'Get Directions',
                icon: Icons.directions_outlined,
                onPressed: query == null
                    ? null
                    : () => openExternal(
                          context,
                          Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': query}),
                          'Could not open directions.',
                        ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _map() {
    final point = LatLng(AppInfo.officeLatitude!, AppInfo.officeLongitude!);
    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.fandom_verse',
        ),
        MarkerLayer(markers: [
          Marker(
            point: point,
            width: 44,
            height: 44,
            child: const Icon(Icons.location_pin, color: AppTheme.pink, size: 44),
          ),
        ]),
        const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
      ],
    );
  }

  Widget _mapPlaceholder() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.accent.withValues(alpha: 0.18), InfoColors.deepPurple, AppTheme.pink.withValues(alpha: 0.12)],
          ),
        ),
        child: Stack(children: [
          // Faint grid so the placeholder still reads as "a map".
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const GlowIcon(Icons.map_outlined, size: 54),
              const SizedBox(height: 12),
              Text('Office location coming soon',
                  style: AppTheme.inter(size: 13, weight: FontWeight.w600, color: InfoColors.lavender)),
            ]),
          ),
        ]),
      );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Frequently asked questions ───────────────────────────────────────────────

class _FaqSection extends StatefulWidget {
  const _FaqSection();

  @override
  State<_FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<_FaqSection> {
  late final Stream<List<Faq>> _faqs = FaqService.instance.watchActive();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Faq>>(
      stream: _faqs,
      builder: (context, snap) {
        final all = snap.data ?? const <Faq>[];
        if (all.isEmpty) return const SizedBox.shrink();
        final words = _query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
        final shown = all.where((f) {
          final text = '${f.question} ${f.answer}'.toLowerCase();
          return words.every(text.contains);
        }).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const InfoSectionHeading(eyebrow: 'QUICK ANSWERS', title: 'Frequently asked questions'),
            if (all.length > 5)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  style: AppTheme.inter(size: 14, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search questions',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                ),
              ),
            GlassCard(
              padding: EdgeInsets.zero,
              child: shown.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text('No questions match "$_query".',
                          style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: Column(children: [
                        for (var i = 0; i < shown.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: InfoColors.glassBorder),
                          Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              key: PageStorageKey('faq-${shown[i].id}'),
                              tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                              iconColor: InfoColors.lavender,
                              collapsedIconColor: AppTheme.textMuted,
                              title: Text(shown[i].question,
                                  style: AppTheme.inter(size: 14, weight: FontWeight.w600, color: Colors.white)),
                              expandedCrossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(shown[i].answer,
                                    style: AppTheme.inter(size: 13, color: AppTheme.textSecondary, height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ]),
                    ),
            ),
          ]),
        );
      },
    );
  }
}
