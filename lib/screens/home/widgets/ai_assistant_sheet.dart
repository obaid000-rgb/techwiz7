import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/chatbot/ai_actions.dart';
import '../../../services/chatbot/ai_assistant_service.dart';
import '../../../services/xp_service.dart';
import '../../../theme/app_theme.dart';
import '../../creators/creator_profile_screen.dart';
import '../../events/event_detail_screen.dart';
import '../../events/my_agenda_screen.dart';
import '../../explore/beginner_fan_hub_screen.dart';
import '../../explore/category_detail_screen.dart';
import '../../explore/fandom_detail_screen.dart';
import '../../explore/glossary_screen.dart';
import '../../fandoms/fandom_page_screen.dart';
import '../../info/about_us_screen.dart';
import '../../info/contact_us_screen.dart';
import '../../profile/following_screen.dart';
import '../../resources/resources_screen.dart';
import '../../shop/cart_screen.dart';
import '../../shop/product_detail_screen.dart';
import '../../shop/shop_tab.dart' show showGuestLoginSheet;
import '../../shop/wishlist_screen.dart';
import '../fan_home_screen.dart';

/// The Fan Helper chat (opened from the robot button on Home).
class AiAssistantSheet extends StatefulWidget {
  const AiAssistantSheet({super.key});

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _service = AiAssistantService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Rebuild the knowledge when the chat opens (cached for 10 minutes).
    _service.prepare().then((_) {
      if (mounted) setState(() {});
    }).catchError((Object e) {
      debugPrint('[AiAssistant] context failed: $e');
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _run(Stream<AiMessage> updates) async {
    setState(() => _busy = true);
    _scrollToEnd();
    AiMessage? last;
    await for (final m in updates) {
      last = m;
      if (!mounted) return;
      setState(() {});
      _scrollToEnd();
    }
    // XP only for real Gemini answers (not offline, busy or blocked).
    if (last != null && !last.offline && !last.failed) {
      XpService.instance.award(XpAction.aiQuestion);
    }
    if (mounted) setState(() => _busy = false);
  }

  void _send([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    _run(_service.send(text));
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  // ── Action buttons ───────────────────────────────────────────────────────

  void _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _needsAccount(String feature, Widget screen) {
    if (AuthService.instance.currentUser == null) {
      showGuestLoginSheet(context, feature: feature);
    } else {
      _push(screen);
    }
  }

  void _open(AssistantAction a) {
    final ctx = _service.context;
    switch (a.kind) {
      case 'fandom':
        _push(FandomPageScreen(fandomId: a.id));
      case 'event':
        final e = ctx?.events[a.id];
        if (e != null) _push(EventDetailScreen(event: e));
      case 'product':
        final p = ctx?.products[a.id];
        if (p != null) _push(ProductDetailScreen(item: p));
      case 'post':
        final p = ctx?.posts[a.id];
        if (p != null) _push(FandomDetailScreen(post: p));
      case 'creator':
        _push(CreatorProfileScreen(creatorId: a.id));
      case 'category':
        final c = ctx?.categoryMap[a.id];
        if (c != null) _push(CategoryDetailScreen(category: c));
      case 'screen':
        switch (a.id) {
          case 'resources':
            _push(const ResourcesScreen());
          // The Events tab has no map/calendar entry point of its own; the
          // button opens the tab, where "Map" and "Calendar" are one tap.
          case 'events_map' || 'events_calendar':
            Navigator.of(context).pop();
            FanHomeScreen.openTab(context, FanHomeScreen.eventsTab);
          case 'my_agenda':
            _needsAccount('My Agenda', const MyAgendaScreen());
          case 'cart':
            _needsAccount('Your cart', const CartScreen());
          case 'wishlist':
            _needsAccount('Your wishlist', const WishlistScreen());
          case 'glossary':
            _push(const GlossaryScreen());
          case 'beginner_hub':
            _push(const BeginnerFanHubScreen());
          case 'profile':
            Navigator.of(context).pop();
            FanHomeScreen.openTab(context, FanHomeScreen.profileTab);
          case 'following':
            _needsAccount('Following fandoms', const FollowingScreen());
          case 'contact':
            _push(const ContactUsScreen());
          case 'about':
            _push(const AboutUsScreen());
        }
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final transcript = _service.transcript;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppTheme.cyan, shape: BoxShape.circle),
                    child: const Icon(Icons.smart_toy, color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fandom AI Assistant', style: AppTheme.orbitron(size: 14, weight: FontWeight.w700)),
                        Text('Ask about the app, events, fandoms and your account',
                            style: AppTheme.inter(size: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (transcript.isNotEmpty)
                    IconButton(
                      tooltip: 'New chat',
                      onPressed: _busy ? null : () => setState(_service.reset),
                      icon: const Icon(Icons.refresh, color: AppTheme.textMuted, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: transcript.isEmpty
                    ? _intro()
                    : ListView(
                        controller: _scroll,
                        shrinkWrap: true,
                        children: [for (final m in transcript) _message(m)],
                      ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _input,
                enabled: !_busy,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                minLines: 1,
                maxLines: 4,
                style: AppTheme.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ask anything about Fandom Verse…',
                  suffixIcon: IconButton(
                    tooltip: 'Send',
                    icon: const Icon(Icons.send, color: AppTheme.cyan),
                    onPressed: _busy ? null : () => _send(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _intro() {
    final starters = assistantStarters(_service.context, AuthService.instance.currentUser);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hi! I know the app, what\'s on right now, and your account. Try:',
              style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in starters)
                ActionChip(
                  label: Text(s, style: AppTheme.inter(size: 12, color: Colors.white)),
                  backgroundColor: AppTheme.bg,
                  side: const BorderSide(color: AppTheme.border),
                  onPressed: () => _send(s),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _message(AiMessage m) {
    if (m.fromUser) return _bubble(Text(m.text, style: _textStyle), fromUser: true);
    if (m.streaming && m.text.isEmpty) return _typing(m.status ?? 'Thinking…');
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bubble(
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              if (m.offline) ...[
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off_rounded, size: 13, color: AppTheme.orange),
                  const SizedBox(width: 5),
                  Text('Offline answer',
                      style: AppTheme.inter(size: 11, weight: FontWeight.w700, color: AppTheme.orange)),
                ]),
                const SizedBox(height: 6),
              ],
              SelectableText(m.text, style: _textStyle),
              if (m.notice != null) ...[
                const SizedBox(height: 6),
                Text(m.notice!, style: AppTheme.inter(size: 11, color: AppTheme.textMuted)),
              ],
            ]),
            fromUser: false,
          ),
          if (m.actions.isNotEmpty || m.retryText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                for (final a in m.actions)
                  OutlinedButton.icon(
                    onPressed: () => _open(a),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.cyan),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.arrow_outward_rounded, size: 14, color: AppTheme.cyan),
                    label: Text(a.label, style: AppTheme.inter(size: 12, color: AppTheme.cyan)),
                  ),
                if (m.retryText != null && !_busy)
                  TextButton.icon(
                    onPressed: () => _run(_service.retry(m)),
                    icon: const Icon(Icons.refresh, size: 14, color: Colors.white70),
                    label: Text('Try again', style: AppTheme.inter(size: 12, color: Colors.white70)),
                  ),
              ]),
            ),
        ],
      ),
    );
  }

  TextStyle get _textStyle => AppTheme.inter(size: 13, color: Colors.white, height: 1.4);

  Widget _bubble(Widget child, {required bool fromUser}) => Align(
        alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: fromUser ? AppTheme.accent.withValues(alpha: 0.35) : AppTheme.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: fromUser ? AppTheme.accent.withValues(alpha: 0.6) : AppTheme.border),
          ),
          child: child,
        ),
      );

  Widget _typing(String label) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
                width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan)),
            const SizedBox(width: 10),
            Text(label, style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
          ]),
        ),
      );
}
