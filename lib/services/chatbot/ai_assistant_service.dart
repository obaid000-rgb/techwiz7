import 'dart:async';
import 'dart:io' show InternetAddress;
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/gemini_config.dart';
import '../auth_service.dart';
import 'ai_actions.dart';
import 'ai_context_builder.dart';
import 'ai_request_context.dart';
import 'local_answerer.dart';

/// What went wrong with one Gemini call (see [AiAssistantService._classify]).
enum _ErrorKind {
  /// No network at all (socket / DNS failure). Confirmed with a DNS lookup
  /// before the local "Offline answer" is shown.
  network,
  /// The call took too long.
  timeout,
  /// 429 rate limit / quota, 503 overloaded ("high demand"), 500 internal.
  /// Temporary: retried automatically.
  transient,
  /// The answer was blocked by safety filters, or came back empty.
  blocked,
  /// Missing or invalid API key.
  badKey,
  /// Anything else (e.g. a 400). Not retried.
  other,
}

const String kAssistantBusy = 'The assistant is busy right now. Please try again in a moment.';
const String kAssistantBlocked = "I can't answer that one. Try asking differently.";
const String kAssistantNoKey = 'The assistant is not available right now.';
const String kAssistantOfflineNotice = "You're offline, so this answer comes from the app's FAQs and glossary.";

/// One message in the chat.
class AiMessage {
  final bool fromUser;
  String text;
  List<AssistantAction> actions;
  /// Still waiting for / receiving the answer.
  bool streaming;
  /// Shown in the typing indicator while waiting ("Still thinking…" during
  /// automatic retries); null shows "Thinking…".
  String? status;
  /// Answered on the device from FAQs / glossary: ONLY when the phone is
  /// really offline.
  bool offline;
  /// Gemini didn't answer (busy, blocked, no key): no XP, "Try again" shown.
  bool failed;
  /// Shown under the answer (why an offline answer was used).
  String? notice;
  /// The question to send again from "Try again".
  String? retryText;

  AiMessage.user(this.text)
      : fromUser = true,
        actions = const [],
        streaming = false,
        offline = false,
        failed = false;

  AiMessage.reply()
      : fromUser = false,
        text = '',
        actions = const [],
        streaming = true,
        offline = false,
        failed = false;
}

/// Gemini-backed Fan Helper. Every answer is written by Gemini, grounded in
/// context picked for each question (ai_request_context.dart). Temporary
/// Gemini errors are retried automatically; the local FAQ/glossary answer
/// is used only when the phone genuinely has no internet.
class AiAssistantService {
  static final AiAssistantService instance = AiAssistantService._();
  AiAssistantService._();

  /// Waits before retry 1, 2 and 3 of a temporary error (429/500/503),
  /// unless the API says how long to wait.
  static const _retryDelays = [Duration(seconds: 2), Duration(seconds: 5), Duration(seconds: 10)];
  static const _timeout = Duration(seconds: 30);
  static const _longTimeout = Duration(seconds: 60);
  /// Messages of chat history sent with each question (4 exchanges).
  static const _historyToSend = 8;
  static const _host = 'generativelanguage.googleapis.com';

  // Test hooks (never set by the app): a fixed context instead of loading
  // Firestore, a model factory (to inject HTTP failures such as a 429) and
  // a connectivity override (to simulate airplane mode).
  @visibleForTesting
  AiContext? debugContext;
  @visibleForTesting
  GenerativeModel Function(String model, String instruction)? debugModelFactory;
  @visibleForTesting
  Future<bool> Function()? debugIsOnline;

  GenerativeModel _model(String name, String instruction) =>
      debugModelFactory?.call(name, instruction) ??
      GenerativeModel(
        model: name,
        apiKey: GeminiConfig.apiKey,
        systemInstruction: Content.system(instruction),
        generationConfig: GenerationConfig(temperature: 0.3, maxOutputTokens: 900),
      );

  /// Successful exchanges only (a failed question is never added), in
  /// memory for this app session; "New chat" clears it.
  final List<Content> _history = [];
  String? _chatUid;

  AiContext? context;

  final List<AiMessage> transcript = [];

  void reset() {
    _history.clear();
    transcript.clear();
  }

  /// Called when the chat opens and before each question: reloads the app
  /// data when the 10-minute cache has expired or the account changed.
  Future<AiContext> prepare() async {
    if (debugContext != null) return context = debugContext!;
    final user = AuthService.instance.currentUser;
    if (_chatUid != user?.uid) {
      reset(); // signed in/out: never mix accounts
      _chatUid = user?.uid;
    }
    try {
      return context = await AiContextBuilder.instance.get();
    } catch (e) {
      // Loading the app's data failed: still ask Gemini, with the rules and
      // the feature guide only.
      debugPrint('[AiAssistant] context failed: $e');
      return context = AiContext.empty(uid: user?.uid, signedIn: user != null);
    }
  }

  String? _labelFor(AiContext ctx, String kind, String id) {
    String cut(String s) => s.length <= 28 ? s : '${s.substring(0, 27)}…';
    return switch (kind) {
      'fandom' => ctx.fandoms[id] == null ? null : 'Open ${cut(ctx.fandoms[id]!.name)}',
      'event' => ctx.events[id] == null ? null : 'Open ${cut(ctx.events[id]!.title)}',
      'product' => ctx.products[id] == null ? null : 'View ${cut(ctx.products[id]!.name)}',
      'post' => ctx.posts[id] == null ? null : 'Read ${cut(ctx.posts[id]!.title)}',
      'creator' => ctx.creators[id] == null ? null : 'Open ${cut(ctx.creators[id]!.name)}',
      'category' => ctx.categoryMap[id] == null ? null : 'Open ${cut(ctx.categoryMap[id]!.name)}',
      _ => null,
    };
  }

  /// Sends [text] and yields the reply as it streams in (the same
  /// [AiMessage] object, updated). Never throws.
  Stream<AiMessage> send(String text) async* {
    final recent = [for (final m in transcript) if (m.fromUser) m.text];
    transcript.add(AiMessage.user(text));
    final reply = AiMessage.reply();
    transcript.add(reply);
    yield reply;

    final ctx = await prepare();

    if (GeminiConfig.apiKey.isEmpty) {
      if (kDebugMode) debugPrint('[AiAssistant] no key: run with --dart-define-from-file=secrets.json');
      _fail(reply, kAssistantNoKey, text);
      yield reply;
      return;
    }

    final instruction = buildRequestInstruction(ctx, text, recent: recent);
    final history = _history.length > _historyToSend
        ? _history.sublist(_history.length - _historyToSend)
        : List.of(_history);
    final contents = [...history, Content.text(text)];
    if (kDebugMode) {
      final chars = instruction.length +
          contents.expand((c) => c.parts).whereType<TextPart>().fold<int>(0, (n, p) => n + p.text.length);
      debugPrint('[AiAssistant] request ~${chars ~/ 4} tokens '
          '(instruction ${instruction.length} chars, ${history.length} history messages)');
    }

    // ── Retry logic ─────────────────────────────────────────────────────
    // Temporary errors (429/500/503) are retried up to 3 times after 2, 5
    // and 10 s (or the delay the API asks for). A timeout is retried once
    // with a longer limit. If the main model still fails, the fallback
    // model gets one try. Only a confirmed-offline phone gets the local
    // answer; an online phone that exhausts the retries gets "busy".
    var model = GeminiConfig.model;
    var timeout = _timeout;
    var retries = 0;
    var timeoutRetried = false;
    var usedFallback = false;
    while (true) {
      var raw = '';
      try {
        final stream = _model(model, instruction).generateContentStream(contents).timeout(timeout);
        await for (final chunk in stream) {
          raw += chunk.text ?? '';
          reply.text = stripActionTags(raw);
          reply.status = null;
          yield reply;
        }
        // A finished stream with no text: blocked or empty.
        if (raw.trim().isEmpty) {
          _fail(reply, kAssistantBlocked, text);
          yield reply;
          return;
        }
        _history
          ..add(Content.text(text))
          ..add(Content.model([TextPart(raw)]));
        reply.text = stripActionTags(raw);
        reply.actions = parseActionTags(raw, (k, id) => _labelFor(ctx, k, id));
        reply.streaming = false;
        reply.status = null;
        yield reply;
        return;
      } catch (e) {
        final kind = _classify(e);
        if (kDebugMode) {
          debugPrint('[AiAssistant] $model failed (${kind.name}): ${e.runtimeType}: $e');
        }
        // Whatever part of an answer arrived is dropped; the retry starts over.
        reply.text = '';

        if (kind == _ErrorKind.blocked) {
          _fail(reply, kAssistantBlocked, text);
          yield reply;
          return;
        }
        if (kind == _ErrorKind.badKey) {
          _fail(reply, kAssistantNoKey, text);
          yield reply;
          return;
        }
        // A socket/DNS error is only "offline" if a DNS lookup agrees;
        // otherwise it was a blip and is retried like a 503.
        final retryable = kind == _ErrorKind.transient ||
            kind == _ErrorKind.timeout ||
            (kind == _ErrorKind.network && await _isOnline());
        if (kind == _ErrorKind.network && !retryable) {
          _offlineAnswer(reply, ctx, text);
          yield reply;
          return;
        }

        Duration? wait;
        if (kind == _ErrorKind.timeout && !timeoutRetried) {
          timeoutRetried = true;
          timeout = _longTimeout;
          wait = Duration.zero;
        } else if (retryable && retries < _retryDelays.length) {
          wait = _retryAfter(e) ?? _retryDelays[retries];
          retries++;
        } else if (retryable && !usedFallback && GeminiConfig.fallbackModel != model) {
          usedFallback = true;
          model = GeminiConfig.fallbackModel;
          timeout = _longTimeout;
          wait = const Duration(seconds: 1);
        }

        if (wait != null) {
          if (kDebugMode) debugPrint('[AiAssistant] retrying with $model in ${wait.inMilliseconds} ms');
          reply.status = 'Still thinking…';
          yield reply;
          await Future<void>.delayed(wait);
          continue;
        }

        // Out of retries. Offline answer only if the phone really is offline.
        if (!await _isOnline()) {
          _offlineAnswer(reply, ctx, text);
        } else {
          _fail(reply, kAssistantBusy, text);
        }
        yield reply;
        return;
      }
    }
  }

  void _fail(AiMessage reply, String message, String question) {
    reply
      ..text = message
      ..failed = true
      ..streaming = false
      ..status = null
      ..retryText = question;
  }

  /// The phone has no internet: answer from the FAQs and glossary.
  void _offlineAnswer(AiMessage reply, AiContext ctx, String question) {
    final local = answerLocally(question, ctx.faqs, ctx.glossary);
    reply
      ..text = local.text
      ..offline = true
      ..streaming = false
      ..status = null
      ..notice = kAssistantOfflineNotice
      ..retryText = question
      ..actions = local.matched
          ? const []
          : [AssistantAction('screen', 'contact', kAssistantScreens['contact']!)];
  }

  /// "Try again": drops the failed exchange and asks the question again.
  Stream<AiMessage> retry(AiMessage failed) {
    final text = failed.retryText ?? '';
    final i = transcript.indexOf(failed);
    if (i > 0) transcript.removeRange(i - 1, i + 1);
    return send(text);
  }

  /// Real connectivity check: can the phone resolve Gemini's host? (No
  /// extra package; 3-second limit.)
  Future<bool> _isOnline() async {
    if (debugIsOnline != null) return debugIsOnline!();
    if (kIsWeb) return true;
    try {
      final r = await InternetAddress.lookup(_host).timeout(const Duration(seconds: 3));
      return r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// The wait the API asks for, when its message says e.g. "Please retry
  /// in 17.5s" (capped at 30 s).
  static Duration? _retryAfter(Object e) {
    final m = RegExp(r'retry in ([0-9.]+)\s*s', caseSensitive: false).firstMatch(e.toString());
    final s = m == null ? null : double.tryParse(m.group(1)!);
    if (s == null) return null;
    return Duration(milliseconds: (s.clamp(1, 30) * 1000).round());
  }

  // ── Error classification ────────────────────────────────────────────────
  // google_generative_ai reports HTTP errors as ServerException with the
  // API's message only (no status code), so the kind is read from the
  // exception type and message:
  //  - InvalidApiKey / "API key not valid" / PERMISSION_DENIED → badKey.
  //  - "high demand", "overloaded", "unavailable" (503), "internal" (500),
  //    "resource exhausted", "quota", "rate limit" (429) → transient.
  //  - "blocked", "safety", "recitation" → blocked.
  //  - Socket / DNS / connection errors from the HTTP client → network.
  //  - TimeoutException → timeout.
  // Before this fix every exception except a bad key showed the offline
  // answer, so a 503 "high demand" looked like the phone was offline.
  static _ErrorKind _classify(Object e) {
    if (e is TimeoutException) return _ErrorKind.timeout;
    if (e is InvalidApiKey) return _ErrorKind.badKey;
    final s = e.toString().toLowerCase();
    if (e is GenerativeAIException) {
      if (s.contains('api key not valid') || s.contains('api_key_invalid') || s.contains('permission_denied')) {
        return _ErrorKind.badKey;
      }
      if (s.contains('high demand') ||
          s.contains('overloaded') ||
          s.contains('unavailable') ||
          s.contains('try again later') ||
          s.contains('internal') ||
          s.contains('resource_exhausted') ||
          s.contains('resource has been exhausted') ||
          s.contains('quota') ||
          s.contains('rate limit') ||
          s.contains('too many requests') ||
          s.contains('deadline')) {
        return _ErrorKind.transient;
      }
      if (s.contains('blocked') || s.contains('safety') || s.contains('recitation')) {
        return _ErrorKind.blocked;
      }
      return _ErrorKind.other;
    }
    if (s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('clientexception') ||
        s.contains('handshakeexception') ||
        s.contains('connection closed') ||
        s.contains('connection reset') ||
        s.contains('connection refused') ||
        s.contains('network is unreachable')) {
      return _ErrorKind.network;
    }
    return _ErrorKind.other;
  }
}

/// Four starter questions for an empty chat, based on the fan's state.
List<String> assistantStarters(AiContext? ctx, UserData? user) => [
      "What's trending this week?",
      user != null && (ctx?.hasFollows ?? user.followedFandomIds.isNotEmpty)
          ? 'Any events for my fandoms?'
          : 'Events near me',
      user == null
          ? 'How do levels work?'
          : (ctx?.atMaxLevel ?? false)
              ? 'What does Legend unlock?'
              : 'How do I reach the next level?',
      user != null && (ctx?.hasOrders ?? false) ? 'Where is my order?' : 'Explain a fandom term',
    ];
