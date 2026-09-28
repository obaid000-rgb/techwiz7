// Fan levels. The level is never stored — it is always calculated from xp.
// Thresholds are the minimum XP for each level:
//   Level 1 Newcomer   0 XP
//   Level 2 Explorer   100 XP
//   Level 3 Fan        250 XP
//   Level 4 Superfan   500 XP   (unlocks Deep Dive posts)
//   Level 5 Legend     1000 XP  (max level)
const List<int> kLevelThresholds = [0, 100, 250, 500, 1000];
const List<String> kLevelNames = ['Newcomer', 'Explorer', 'Fan', 'Superfan', 'Legend'];
const int kMaxLevel = 5;
const int kDeepDiveLevel = 4;

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

/// Deep Dive gate: admins always pass; everyone else needs Level 4.
/// Guests (not signed in) never pass.
bool canOpenDeepDive({required bool signedIn, required bool isAdmin, required int xp}) =>
    isAdmin || (signedIn && levelFor(xp) >= kDeepDiveLevel);
