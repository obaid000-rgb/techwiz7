import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/gemini_config.dart';
import '../auth_service.dart';
import 'ai_actions.dart';
import 'ai_context_builder.dart';
import 'local_answerer.dart';

/// Why Gemini couldn't answer — each maps to its own notice.
enum AiAssistantFailure { offline, rateLimited, badKey, unavailable }

String aiFailureNotice(AiAssistantFailure f) => switch (f) {
      AiAssistantFailure.rateLimited => 'Lots of questions right now. Try again in a minute.',
      AiAssistantFailure.badKey => 'The assistant is not available right now.',
      AiAssistantFailure.offline => "Couldn't reach the assistant. Check your connection.",
      AiAssistantFailure.unavailable => "Couldn't reach the assistant right now.",
    };

/// One message in the chat.
class AiMessage {
  final bool fromUser;
  String text;
  List<AssistantAction> actions;
  /// Still streaming in.
  bool streaming;
  /// Answered on the device from FAQs / glossary (Gemini failed).
  bool offline;
  /// Shown above an offline answer (why Gemini wasn't used).
  String? notice;
  /// The question to send again from "Try again".
  String? retryText;

  AiMessage.user(this.text)
      : fromUser = true,
        actions = const [],
        streaming = false,
        offline = false;

  AiMessage.reply()
      : fromUser = false,
        text = '',
        actions = const [],
        streaming = true,
        offline = false;
}

/// Gemini-backed Fan Helper. Every answer is written by Gemini, grounded in
/// the context from [AiContextBuilder] (feature guide + live content +
/// the fan's own account). When Gemini can't be reached, a local answer is
/// given from the FAQs and glossary instead.
class AiAssistantService {
  static final AiAssistantService instance = AiAssistantService._();
  AiAssistantService._();

  static const Duration _timeout = Duration(seconds: 45);

  GenerativeModel _modelWith(String instruction) => GenerativeModel(
        model: GeminiConfig.model,
        apiKey: GeminiConfig.apiKey,
        systemInstruction: Content.system(instruction),
        generationConfig: GenerationConfig(temperature: 0.3, maxOutputTokens: 900),
      );

  // One ChatSession per app session (as before): the package keeps the
  // running history and resends it, so follow-ups keep their context. It
  // lives in memory only; "New chat" starts fresh.
  ChatSession? _chat;
  String? _chatInstruction;
  String? _chatUid;

  AiContext? context;

  final List<AiMessage> transcript = [];

  void reset() {
    _chat = null;
    _chatInstruction = null;
    transcript.clear();
  }

  /// Called when the chat opens (and before each question): rebuilds the
  /// context when the 10-minute cache has expired or the account changed.
  /// A chat already in progress keeps its history under the new context.
  Future<AiContext> prepare() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (_chatUid != null && _chatUid != uid) reset(); // signed in/out: never mix accounts
    final ctx = await AiContextBuilder.instance.get();
    context = ctx;
    if (_chat != null && _chatInstruction != ctx.systemInstruction) {
      final history = _chat!.history.toList();
      _chat = _modelWith(ctx.systemInstruction).startChat(history: history);
      _chatInstruction = ctx.systemInstruction;
    }
    return ctx;
  }

  String? _labelFor(AiContext ctx, String kind, String id) {
    String cut(String s) => s.length <= 28 ? s : '${s.substring(0, 27)}…';
    return switch (kind) {
      'fandom' => ctx.fandoms[id] == null ? null : 'Open ${cut(ctx.fandoms[id]!.name)}',
      'event' => ctx.events[id] == null ? null : 'Open ${cut(ctx.events[id]!.title)}',
      'product' => ctx.products[id] == null ? null : 'View ${cut(ctx.products[id]!.name)}',
      'post' => ctx.posts[id] == null ? null : 'Read ${cut(ctx.posts[id]!.title)}',
      'creator' => ctx.creators[id] == null ? null : 'Open ${cut(ctx.creators[id]!.name)}',
      'category' => ctx.categories[id] == null ? null : 'Open ${cut(ctx.categories[id]!.name)}',
      _ => null,
    };
  }

  /// Sends [text] and yields the reply as it streams in (the same
  /// [AiMessage] object, updated). Returns normally in every case: when
  /// Gemini fails the reply is a local answer with [AiMessage.offline] set.
  Stream<AiMessage> send(String text) async* {
    transcript.add(AiMessage.user(text));
    final reply = AiMessage.reply();
    transcript.add(reply);
    yield reply;

    final ctx = await prepare();
    var raw = '';
    try {
      if (GeminiConfig.apiKey.isEmpty) {
        if (kDebugMode) debugPrint('[AiAssistant] no key: run with --dart-define-from-file=secrets.json');
        throw const _Failure(AiAssistantFailure.badKey);
      }
      if (_chat == null) {
        _chat = _modelWith(ctx.systemInstruction).startChat();
        _chatInstruction = ctx.systemInstruction;
        _chatUid = ctx.uid;
      }
      await for (final chunk in _chat!.sendMessageStream(Content.text(text)).timeout(_timeout)) {
        raw += chunk.text ?? '';
        reply.text = stripActionTags(raw);
        yield reply;
      }
      if (raw.trim().isEmpty) throw const _Failure(AiAssistantFailure.unavailable);
      reply.text = stripActionTags(raw);
      reply.actions = parseActionTags(raw, (k, id) => _labelFor(ctx, k, id));
      reply.streaming = false;
      yield reply;
    } catch (e) {
      final failure = e is _Failure ? e.kind : _classify(e);
      if (kDebugMode) debugPrint('[AiAssistant] ${failure.name}: $e');
      reply.streaming = false;
      if (raw.trim().isNotEmpty) {
        // Cut off mid-answer: keep what arrived and offer to ask again.
        reply.text = stripActionTags(raw);
        reply.notice = aiFailureNotice(failure);
        reply.retryText = text;
      } else {
        final local = answerLocally(text, ctx.faqs, ctx.glossary);
        reply.text = local.text;
        reply.offline = true;
        reply.notice = aiFailureNotice(failure);
        reply.retryText = text;
        reply.actions = local.matched
            ? const []
            : [AssistantAction('screen', 'contact', kAssistantScreens['contact']!)];
      }
      yield reply;
    }
  }

  /// "Try again": drops the failed exchange and asks the question again.
  Stream<AiMessage> retry(AiMessage failed) {
    final text = failed.retryText ?? '';
    final i = transcript.indexOf(failed);
    if (i > 0) transcript.removeRange(i - 1, i + 1);
    return send(text);
  }

  static AiAssistantFailure _classify(Object e) {
    if (e is InvalidApiKey) return AiAssistantFailure.badKey;
    if (e is TimeoutException) return AiAssistantFailure.offline;
    final s = e.toString().toLowerCase();
    // Network first: these messages include the request URL, which itself
    // contains words like "generateContent".
    if (s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('clientexception') ||
        s.contains('connection') ||
        s.contains('network')) {
      return AiAssistantFailure.offline;
    }
    if (s.contains('resource_exhausted') ||
        s.contains('quota') ||
        s.contains('rate limit') ||
        s.contains('too many requests') ||
        s.contains('429')) {
      return AiAssistantFailure.rateLimited;
    }
    if (s.contains('api key') || s.contains('api_key') || s.contains('permission_denied')) {
      return AiAssistantFailure.badKey;
    }
    return AiAssistantFailure.unavailable;
  }
}

class _Failure implements Exception {
  final AiAssistantFailure kind;
  const _Failure(this.kind);
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
