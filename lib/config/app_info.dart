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
  static const String? supportEmail = null; // e.g. 'support@yourdomain.com'
  static const String? phone = null; // e.g. '+92 300 0000000'
  static const String? workingHours = null; // e.g. 'Mon–Fri, 9:00–17:00 (PKT)'

  // ── Office location (null = not published yet) ─────────────────────────────
  static const String? officeAddress = null; // e.g. 'Street, Area, City, Country'
  static const double? officeLatitude = null; // e.g. 24.8607
  static const double? officeLongitude = null; // e.g. 67.0011

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

  // ── Team (placeholders — replace with your real team) ──────────────────────
  /// `photoUrl` can stay null; an initial is shown instead.
  static const List<TeamMember> team = [
    TeamMember(name: 'Team Member', role: 'Role', isPlaceholder: true),
    TeamMember(name: 'Team Member', role: 'Role', isPlaceholder: true),
    TeamMember(name: 'Team Member', role: 'Role', isPlaceholder: true),
  ];

  static bool get hasOfficeCoordinates => officeLatitude != null && officeLongitude != null;
  static bool get hasOfficeLocation => officeAddress != null || hasOfficeCoordinates;
}

class TeamMember {
  final String name;
  final String role;
  final String? photoUrl;
  final bool isPlaceholder;
  const TeamMember({
    required this.name,
    required this.role,
    this.photoUrl,
    this.isPlaceholder = false,
  });
}
