import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';
import 'ai_assistant_knowledge.dart';

/// Why a message couldn't be answered — each maps to its own message.
enum AiAssistantFailure { offline, rateLimited, badKey, unavailable }

class AiAssistantException implements Exception {
  final AiAssistantFailure kind;
  const AiAssistantException(this.kind);

  String get message => switch (kind) {
        AiAssistantFailure.offline =>
          "Couldn't reach the assistant, check your connection and try again.",
        AiAssistantFailure.rateLimited =>
          'The assistant is busy right now. Please wait a moment and try again.',
        AiAssistantFailure.badKey =>
          'The assistant is not available right now (configuration problem).',
        AiAssistantFailure.unavailable =>
          "Couldn't reach the assistant, check your connection and try again.",
      };
}

/// Gemini-backed help assistant, scoped to questions about Fandom Verse.
class AiAssistantService {
  static final AiAssistantService instance = AiAssistantService._();
  AiAssistantService._();

  static const Duration _timeout = Duration(seconds: 45);

  // The system instruction (see ai_assistant_knowledge.dart) is attached to
  // the model itself, so Gemini receives it with every request and it can't
  // be pushed out of the conversation by user messages. Temperature is low
  // so feature answers stay faithful to the written knowledge base and the
  // refusal line is repeated verbatim rather than paraphrased.
  late final GenerativeModel _model = GenerativeModel(
    model: GeminiConfig.model,
    apiKey: GeminiConfig.apiKey,
    systemInstruction: Content.system(kAssistantSystemInstruction),
    generationConfig: GenerationConfig(temperature: 0.2, maxOutputTokens: 700),
  );

  // One ChatSession per app launch: the package keeps the running history
  // and resends it with each message, so follow-ups ("and how do I remove
  // it?") keep their context. It lives only in memory — closing the app or
  // tapping "New chat" starts fresh; nothing is stored on the device or in
  // Firestore.
  ChatSession? _chat;

  /// Messages exchanged in the current session, for redrawing the sheet
  /// when it's reopened. true = from the user.
  final List<({bool fromUser, String text})> transcript = [];

  void reset() {
    _chat = null;
    transcript.clear();
  }

  /// Sends [text] and returns the reply. Throws [AiAssistantException].
  Future<String> ask(String text) async {
    _chat ??= _model.startChat();
    transcript.add((fromUser: true, text: text));
    try {
      final response = await _chat!.sendMessage(Content.text(text)).timeout(_timeout);
      final reply = response.text?.trim();
      if (reply == null || reply.isEmpty) throw const AiAssistantException(AiAssistantFailure.unavailable);
      transcript.add((fromUser: false, text: reply));
      return reply;
    } catch (e) {
      transcript.removeLast(); // the failed question isn't part of the chat
      final failure = _classify(e);
      if (kDebugMode) debugPrint('[AiAssistant] ${failure.name}: $e');
      throw AiAssistantException(failure);
    }
  }

  static AiAssistantFailure _classify(Object e) {
    if (e is AiAssistantException) return e.kind;
    if (e is InvalidApiKey) return AiAssistantFailure.badKey;
    if (e is TimeoutException) {
      return AiAssistantFailure.offline;
    }
    final s = e.toString().toLowerCase();
    // Network first: these messages include the request URL, which itself
    // contains words like "generateContent".
    if (s.contains('socketexception') || s.contains('failed host lookup') ||
        s.contains('clientexception') || s.contains('connection') || s.contains('network')) {
      return AiAssistantFailure.offline;
    }
    if (s.contains('resource_exhausted') || s.contains('quota') || s.contains('rate limit') ||
        s.contains('too many requests')) {
      return AiAssistantFailure.rateLimited;
    }
    if (s.contains('api key') || s.contains('api_key')) return AiAssistantFailure.badKey;
    return AiAssistantFailure.unavailable;
  }
}
