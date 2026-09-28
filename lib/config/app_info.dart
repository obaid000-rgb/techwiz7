/// Everything shown on the About Us and Contact Us pages that describes the
/// real organisation lives here, so it can be filled in without touching UI
/// code. Leave a value null until you have the real one — the pages show a
/// tidy "coming soon" state instead of made-up details.
class AppInfo {
  AppInfo._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const String appName = 'Fandom Verse';
  static const String edition = 'Pocket Edition';
  static const String tagline = 'Your pocket guide to every fandom.';

  // ── Contact details (null = not published yet) ─────────────────────────────
  static const String teamName = 'The Fandom Verse Team';
  static const String? supportEmail = 'fluttersquad78@gmail.com';
  static const String? phone = '+92 300 1234567'; // DEMO number, not real
  static const String? workingHours = 'Mon–Sat, 9:00 AM – 9:00 PM (PKT)';

  // ── Office location (Contact Us map) ───────────────────────────────────────
  // Aptech Learning, Shahrah-e-Faisal Center, Karachi.
  // Nullable on purpose: set back to null to show "coming soon".
  // ignore_for_file: unnecessary_nullable_for_final_variable_declarations
  static const String? officeAddress = 'Aptech Learning, Shahrah-e-Faisal Center, Karachi, Pakistan';
  static const double? officeLatitude = 24.8627;
  static const double? officeLongitude = 67.0716;

  // ── About Us copy (describes only what the app really does) ────────────────
  static const String story =
      'Fandom Verse started with a simple idea: fans shouldn\'t need a dozen '
      'tabs, forums and shops to follow the worlds they love. So we built one '
      'place for it all — the lore, the events and the merch — and made it fit '
      'in your pocket.';
  static const String mission =
      'To make every fandom easy to explore — welcoming to newcomers, deep '
      'enough for experts, and connected to the real-world events and '
      'merchandise that bring fans together.';

  // Team members for About Us live in Firestore (`teamMembers`), managed in
  // the admin panel under "About Us Team".

  static bool get hasOfficeCoordinates => officeLatitude != null && officeLongitude != null;
  static bool get hasOfficeLocation => officeAddress != null || hasOfficeCoordinates;
}

