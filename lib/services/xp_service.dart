import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../utils/levels.dart';
import 'auth_service.dart';
import 'firestore_db.dart';
import 'post_service.dart';

enum XpAction { dailyOpen, firstPostOpen, firstFollow, aiQuestion, order }

class XpService {
  static final XpService instance = XpService._();
  XpService._();

  static const String boxName = 'xp_progress';
  static const int aiDailyLimit = 5;
  static const Map<XpAction, int> points = {
    XpAction.dailyOpen: 10,
    XpAction.firstPostOpen: 5,
    XpAction.firstFollow: 10,
    XpAction.aiQuestion: 2,
    XpAction.order: 20,
  };


  final ValueNotifier<int?> levelUps = ValueNotifier(null);

  Future<Box> _box() => Hive.openBox(boxName);

  Future<int> award(XpAction action, {String? targetId, DateTime? now}) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return 0;
    final uid = user.uid;
    try {
      final box = await _box();
      final day = PostService.todayKey(now);
      Future<void> Function()? undo;
      switch (action) {
        case XpAction.dailyOpen:
          final key = '$uid:lastOpenDay';
          final previous = box.get(key);
          if (previous == day) return 0;
          await box.put(key, day);
          undo = () => box.put(key, previous);
        case XpAction.firstPostOpen:
        case XpAction.firstFollow:
          if (targetId == null || targetId.isEmpty) return 0;
          final key = action == XpAction.firstPostOpen
              ? '$uid:openedPosts'
              : '$uid:followedFandoms';
          final seen = List<String>.from(box.get(key) ?? const <String>[]);
          if (seen.contains(targetId)) return 0;
          await box.put(key, [...seen, targetId]);
          undo = () => box.put(key, seen);
        case XpAction.aiQuestion:
          final dayKey = '$uid:aiDay';
          final countKey = '$uid:aiCount';
          final sameDay = box.get(dayKey) == day;
          final count = sameDay ? (box.get(countKey) as int? ?? 0) : 0;
          if (count >= aiDailyLimit) return 0;
          final prevDay = box.get(dayKey);
          final prevCount = box.get(countKey);
          await box.put(dayKey, day);
          await box.put(countKey, count + 1);
          undo = () async {
            await box.put(dayKey, prevDay);
            await box.put(countKey, prevCount);
          };
        case XpAction.order:
          break;
      }

      final gained = points[action]!;
      try {
        await FirestoreDb.instance
            .collection('users')
            .doc(uid)
            .update({'xp': FieldValue.increment(gained)});
      } catch (e) {
        await undo?.call();
        rethrow;
      }

      final current = AuthService.instance.currentUser;
      if (current != null && current.uid == uid) {
        final before = current.xp;
        final after = before + gained;
        AuthService.instance.userNotifier.value = current.copyWith(xp: after);
        if (levelFor(after) > levelFor(before)) levelUps.value = levelFor(after);
      }
      return gained;
    } catch (e) {
      debugPrint('XP award ($action) failed: $e');
      return 0;
    }
  }
}
