class GeminiConfig {
  GeminiConfig._();

  /// Supplied at build time, never committed (GitHub blocks pushes that
  /// contain API keys). Put it in techwiz7/secrets.json (git-ignored; see
  /// secrets.example.json) and run/build with:
  ///   flutter run --dart-define-from-file=secrets.json
  ///   flutter build apk --release --dart-define-from-file=secrets.json
  /// Without it the app still builds; the AI Assistant just reports that
  /// it's not available.
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String model = 'gemini-3.1-flash-lite';
  /// Tried once only after [model] still fails its automatic retries (e.g.
  /// repeated 503 "high demand"). Same family, confirmed available on the
  /// free tier (2026-09-29).
  static const String fallbackModel = 'gemini-3.5-flash-lite';
}
