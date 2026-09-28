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

  test('Deep Dive gate', () {
    expect(canOpenDeepDive(signedIn: false, isAdmin: false, xp: 9999), isFalse);
    expect(canOpenDeepDive(signedIn: true, isAdmin: false, xp: 499), isFalse);
    expect(canOpenDeepDive(signedIn: true, isAdmin: false, xp: 500), isTrue);
    expect(canOpenDeepDive(signedIn: true, isAdmin: true, xp: 0), isTrue);
  });
}
