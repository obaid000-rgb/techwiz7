import 'package:fandom_verse/models/post.dart';
import 'package:fandom_verse/services/auth_service.dart';
import 'package:fandom_verse/utils/levels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('levelFor at every threshold', () {
    expect(levelFor(0), 1);
    expect(levelFor(-5), 1);
    expect(levelFor(99), 1);
    expect(levelFor(100), 2);
    expect(levelFor(249), 2);
    expect(levelFor(250), 3);
    expect(levelFor(499), 3);
    expect(levelFor(500), 4);
    expect(levelFor(999), 4);
    expect(levelFor(1000), 5);
    expect(levelFor(99999), 5);
  });

  test('levelName', () {
    expect([for (var l = 1; l <= 5; l++) levelName(l)],
        ['Newcomer', 'Explorer', 'Fan', 'Superfan', 'Legend']);
  });

  test('xpForNextLevel / xpToNextLevel / xpToLevel', () {
    expect(xpForNextLevel(0), 100);
    expect(xpForNextLevel(120), 250);
    expect(xpForNextLevel(999), 1000);
    expect(xpForNextLevel(1000), isNull);
    expect(xpToNextLevel(40), 60);
    expect(xpToNextLevel(1500), 0);
    expect(xpToLevel(320, 4), 180);
    expect(xpToLevel(600, 4), 0);
  });

  test('progressToNextLevel', () {
    expect(progressToNextLevel(0), 0.0);
    expect(progressToNextLevel(50), 0.5);
    expect(progressToNextLevel(175), 0.5); // halfway 100 → 250
    expect(progressToNextLevel(750), 0.5); // halfway 500 → 1000
    expect(progressToNextLevel(1000), 1.0);
    expect(progressToNextLevel(5000), 1.0);
  });

  test('Deep Dive gate: Level 3, admins always, guests never', () {
    UserData fan(int xp, {String role = 'fan'}) => UserData(uid: 'u', name: 'A', email: 'a@b.c', xp: xp, role: role);
    expect(DEEP_DIVE_LEVEL, 3);
    expect(canViewDeepDive(null), isFalse);
    expect(canViewDeepDive(fan(0)), isFalse); // brand-new account
    expect(canViewDeepDive(fan(249)), isFalse);
    expect(canViewDeepDive(fan(250)), isTrue);
    expect(canViewDeepDive(fan(0, role: 'admin')), isTrue);
    expect(canViewDeepDive(fan(0, role: '')), isFalse);
  });

  test('isDeepDive recognizes every stored spelling', () {
    for (final raw in ['deep', 'Deep', 'Deep Dive', 'deep_dive', 'DeepDive', 'deep-dive', 'expert']) {
      final post = Post.fromMap({'contentDepth': raw}, 'p');
      expect(isDeepDive(post), isTrue, reason: raw);
      expect(post.contentDepth, kDepthDeep, reason: raw);
    }
    for (final raw in ['beginner', '', null, 42, 'news']) {
      expect(isDeepDive(Post.fromMap({'contentDepth': raw}, 'p')), isFalse, reason: '$raw');
    }
    final newFan = UserData(uid: 'u', name: 'A', email: 'a@b.c');
    expect(isDeepDiveLockedFor(Post.fromMap({'contentDepth': 'deep'}, 'p'), newFan), isTrue);
    expect(isDeepDiveLockedFor(Post.fromMap({'contentDepth': 'beginner'}, 'p'), newFan), isFalse);
  });
}
