import 'dart:math' as math;

import '../models/fandom.dart';

/// Compact counts for follower/view labels: 999, 1.2K, 34K, 1.5M.
/// One decimal below 10K / 10M, always rounded DOWN so a count never looks
/// bigger than it is (1250 → 1.2K, 1999 → 1.9K), and a trailing ".0" is
/// dropped (1000 → 1K).
String formatCount(int n) {
  if (n < 0) n = 0;
  String oneDecimal(int value, int unit, String suffix) {
    final tenths = value * 10 ~/ unit;
    final whole = tenths ~/ 10;
    final frac = tenths % 10;
    return frac == 0 ? '$whole$suffix' : '$whole.$frac$suffix';
  }

  if (n < 1000) return '$n';
  if (n < 10000) return oneDecimal(n, 1000, 'K');
  if (n < 1000000) return '${n ~/ 1000}K';
  if (n < 10000000) return oneDecimal(n, 1000000, 'M');
  return '${n ~/ 1000000}M';
}

String followersLabel(int n) =>
    '${formatCount(n)} follower${n == 1 ? '' : 's'}';

/// ISO-8601 week of [date] (local calendar day) as "2026-W40". Weeks start
/// on Monday; week 1 is the one containing the year's first Thursday, so
/// late-December / early-January days can belong to the neighbouring year.
String isoWeekKey(DateTime date) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final thursday = day.add(Duration(days: 4 - day.weekday));
  final week = thursday.difference(DateTime.utc(thursday.year)).inDays ~/ 7 + 1;
  return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
}

// Trending score of a fandom:
//   weekViewCount + 5 × weekFollowCount + 2 × ln(1 + followerCount)
// A new follower is worth five page views. The all-time follower count
// only adds a gentle, logarithmic head start so big fandoms don't lock the
// top spots. The weekly counters only count when weekKey is the CURRENT
// ISO week: last week's numbers are stale and score 0 until the first
// view/follow of this week resets them.
double fandomTrendingScore(Fandom f, DateTime now) {
  final thisWeek = f.weekKey == isoWeekKey(now);
  final views = thisWeek ? math.max(0, f.weekViewCount) : 0;
  final follows = thisWeek ? math.max(0, f.weekFollowCount) : 0;
  return views + 5 * follows + 2 * math.log(1 + math.max(0, f.followerCount));
}

/// Active fandoms for the Home carousel / suggestions: pinned (isTrending)
/// first, then the rest by score (ties: more followers, then name), up to
/// [limit]. When nothing is pinned and every score is 0 the ranking says
/// nothing, so with [fallbackToMostFollowed] it returns the most-followed
/// fandoms instead, and without it an empty list.
List<Fandom> rankTrendingFandoms(
  List<Fandom> fandoms,
  DateTime now, {
  int limit = 8,
  bool fallbackToMostFollowed = true,
}) {
  final active = fandoms.where((f) => f.isActive).toList();
  final scores = {for (final f in active) f.id: fandomTrendingScore(f, now)};
  int byScore(Fandom a, Fandom b) {
    final s = scores[b.id]!.compareTo(scores[a.id]!);
    if (s != 0) return s;
    final c = b.followerCount.compareTo(a.followerCount);
    return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  final pinned = active.where((f) => f.isTrending).toList()..sort(byScore);
  final rest = active.where((f) => !f.isTrending).toList()..sort(byScore);
  if (pinned.isEmpty && rest.every((f) => scores[f.id] == 0)) {
    if (!fallbackToMostFollowed) return const [];
    return rest.take(limit).toList();
  }
  return [...pinned, ...rest].take(limit).toList();
}

/// IDs of the top [n] fandoms by score among [fandoms] (score > 0 only).
Set<String> topTrendingIds(List<Fandom> fandoms, DateTime now, {int n = 3}) {
  final scored = [
    for (final f in fandoms)
      if (f.isActive) (f, fandomTrendingScore(f, now)),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  return {
    for (final (f, s) in scored.take(n))
      if (s > 0) f.id,
  };
}
