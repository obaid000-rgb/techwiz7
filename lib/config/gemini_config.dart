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
}
