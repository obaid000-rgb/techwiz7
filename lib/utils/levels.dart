import '../models/post.dart';
import '../services/auth_service.dart' show UserData;

// Fan levels. The level is never stored — it is always calculated from xp.
// Thresholds are the minimum XP for each level:
//   Level 1 Newcomer   0 XP
//   Level 2 Explorer   100 XP
//   Level 3 Fan        250 XP   (unlocks Deep Dive posts)
//   Level 4 Superfan   500 XP
//   Level 5 Legend     1000 XP  (max level)
const List<int> kLevelThresholds = [0, 100, 250, 500, 1000];
const List<String> kLevelNames = ['Newcomer', 'Explorer', 'Fan', 'Superfan', 'Legend'];
const int kMaxLevel = 5;
/// The level that unlocks Deep Dive posts. The ONE place this is set:
/// the lock, the badges, the locked screen and the Fan Helper all read it.
// ignore: constant_identifier_names
const int DEEP_DIVE_LEVEL = 3;

/// Level (1–5) for [xp].
int levelFor(int xp) {
  var level = 1;
  for (var i = 0; i < kLevelThresholds.length; i++) {
    if (xp >= kLevelThresholds[i]) level = i + 1;
  }
  return level;
}

String levelName(int level) => kLevelNames[level.clamp(1, kMaxLevel) - 1];

/// XP needed to REACH the next level (its threshold), or null at max level.
int? xpForNextLevel(int xp) {
  final level = levelFor(xp);
  return level >= kMaxLevel ? null : kLevelThresholds[level];
}

/// XP still missing to the next level (0 at max level).
int xpToNextLevel(int xp) {
  final next = xpForNextLevel(xp);
  return next == null ? 0 : next - xp;
}

/// XP missing to reach [level] (0 once reached).
int xpToLevel(int xp, int level) {
  final target = kLevelThresholds[level.clamp(1, kMaxLevel) - 1];
  return xp >= target ? 0 : target - xp;
}

/// Progress from the current level's threshold to the next, 0.0–1.0
/// (1.0 at max level).
double progressToNextLevel(int xp) {
  final level = levelFor(xp);
  if (level >= kMaxLevel) return 1.0;
  final start = kLevelThresholds[level - 1];
  final end = kLevelThresholds[level];
  return ((xp - start) / (end - start)).clamp(0.0, 1.0);
}

/// Deep Dive gate, used on every route into a post (Content Detail, the
/// saved offline copy, bookmarking, card badges and the Fan Helper):
///  - admins can always view Deep Dive;
///  - guests (null user) never can;
///  - everyone else needs Level [DEEP_DIVE_LEVEL] or higher, worked out from
///    their xp (a new account starts at 0 XP, Level 1).
bool canViewDeepDive(UserData? user) =>
    user != null && (user.isAdmin || levelFor(user.xp) >= DEEP_DIVE_LEVEL);

/// True when [post] is a Deep Dive post, whatever spelling its stored depth
/// uses (see normalizeContentDepth). Always use this instead of comparing
/// contentDepth directly.
bool isDeepDive(Post post) => normalizeContentDepth(post.contentDepth) == kDepthDeep;

/// True when [user] must see the locked screen instead of [post].
bool isDeepDiveLockedFor(Post post, UserData? user) => isDeepDive(post) && !canViewDeepDive(user);
