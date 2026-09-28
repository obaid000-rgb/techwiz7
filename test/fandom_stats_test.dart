import 'dart:math' as math;

import 'package:fandom_verse/models/fandom.dart';
import 'package:fandom_verse/utils/fandom_stats.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 9, 28, 12); // Monday of ISO week 2026-W40
final thisWeek = isoWeekKey(now);

Fandom f(String id, {int followers = 0, int weekViews = 0, int weekFollows = 0,
        String? week, bool pinned = false, bool active = true}) =>
    Fandom(
      id: id,
      categoryId: 'c',
      categoryName: 'C',
      name: id,
      followerCount: followers,
      weekViewCount: weekViews,
      weekFollowCount: weekFollows,
      weekKey: week ?? thisWeek,
      isTrending: pinned,
      isActive: active,
      createdAt: now,
    );

void main() {
  test('formatCount', () {
    expect(formatCount(0), '0');
    expect(formatCount(999), '999');
    expect(formatCount(1000), '1K');
    expect(formatCount(1250), '1.2K');
    expect(formatCount(1999), '1.9K');
    expect(formatCount(9999), '9.9K');
    expect(formatCount(34000), '34K');
    expect(formatCount(34999), '34K');
    expect(formatCount(999999), '999K');
    expect(formatCount(1500000), '1.5M');
    expect(formatCount(12000000), '12M');
    expect(formatCount(-3), '0');
    expect(followersLabel(1), '1 follower');
    expect(followersLabel(1250), '1.2K followers');
  });

  test('isoWeekKey', () {
    expect(isoWeekKey(DateTime(2026, 9, 28)), '2026-W40');
    expect(isoWeekKey(DateTime(2026, 10, 4, 23, 59)), '2026-W40'); // Sunday
    expect(isoWeekKey(DateTime(2026, 10, 5)), '2026-W41'); // Monday
    expect(isoWeekKey(DateTime(2027, 1, 1)), '2026-W53'); // belongs to 2026
    expect(isoWeekKey(DateTime(2024, 12, 30)), '2025-W01'); // belongs to 2025
    expect(isoWeekKey(DateTime(2026, 1, 1)), '2026-W01');
  });

  test('score formula and stale week', () {
    final a = f('a', followers: 10, weekViews: 3, weekFollows: 2);
    expect(fandomTrendingScore(a, now), closeTo(3 + 5 * 2 + 2 * math.log(11), 1e-9));
    final stale = f('b', followers: 10, weekViews: 50, weekFollows: 9, week: '2026-W39');
    expect(fandomTrendingScore(stale, now), closeTo(2 * math.log(11), 1e-9));
    expect(fandomTrendingScore(f('c'), now), 0);
    // a follow is worth five views
    expect(fandomTrendingScore(f('d', weekFollows: 1), now),
        fandomTrendingScore(f('e', weekViews: 5), now));
  });

  test('ranking: pinned first, then score, limit 8, inactive excluded', () {
    final list = [
      f('low', weekViews: 1),
      f('high', weekViews: 30),
      f('pinnedLow', pinned: true),
      f('mid', weekFollows: 2),
      f('gone', weekViews: 99, active: false),
      for (var i = 0; i < 10; i++) f('x$i'),
    ];
    final ranked = rankTrendingFandoms(list, now).map((e) => e.id).toList();
    expect(ranked.take(4), ['pinnedLow', 'high', 'mid', 'low']);
    expect(ranked.length, 8);
    expect(ranked, isNot(contains('gone')));
  });

  test('a fandom viewed by 3 accounts moves up', () {
    final before = rankTrendingFandoms([f('a', followers: 5), f('b', followers: 5)], now);
    expect(before.first.id, 'a'); // tie → name
    final after = rankTrendingFandoms([f('a', followers: 5), f('b', followers: 5, weekViews: 3)], now);
    expect(after.first.id, 'b');
  });

  test('fallback: nothing pinned and all scores 0', () {
    final zero = [f('b'), f('a')];
    expect(rankTrendingFandoms(zero, now).map((e) => e.id), ['a', 'b']);
    expect(rankTrendingFandoms(zero, now, fallbackToMostFollowed: false), isEmpty);
    expect(rankTrendingFandoms([f('b'), f('a', week: '2020-W01', weekViews: 9)], now,
            fallbackToMostFollowed: false),
        isEmpty);
  });

  test('topTrendingIds: top 3 with score > 0', () {
    final list = [f('a', weekViews: 5), f('b', weekViews: 4), f('c', weekViews: 3), f('d', weekViews: 2), f('e')];
    expect(topTrendingIds(list, now), {'a', 'b', 'c'});
    expect(topTrendingIds([f('z')], now), isEmpty);
  });
}
