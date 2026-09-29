import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/post.dart';
import 'post_service.dart';


class TrendingService {
  static final TrendingService instance = TrendingService._();
  TrendingService._();

  final ValueNotifier<String?> trendingPostId = ValueNotifier<String?>(null);

  StreamSubscription<List<Post>>? _sub;
  Timer? _midnight;
  AppLifecycleListener? _lifecycle;
  String? _day;

  /// Idempotent; call once at startup.
  void start() {
    _lifecycle ??= AppLifecycleListener(onResume: _refreshIfNewDay);
    if (_sub == null) _subscribe();
  }

  void _refreshIfNewDay() {
    if (_day != PostService.todayKey()) _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    _midnight?.cancel();
    final day = PostService.todayKey();
    _day = day;
    trendingPostId.value = null; // nothing counts until today's data arrives
    _sub = PostService.instance.watchViewedToday(day).listen(
      (posts) => trendingPostId.value = pickTrending(posts, day),
      onError: (Object e) {
        if (kDebugMode) debugPrint('[Trending] query failed: $e');
      },
    );
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(nextMidnight.difference(now) + const Duration(seconds: 1), _subscribe);
  }


  static String? pickTrending(List<Post> posts, String today) {
    Post? best;
    for (final p in posts) {
      if (!p.isActive || p.todayViewDate != today || p.todayViewCount <= 0) continue;
      if (best == null ||
          p.todayViewCount > best.todayViewCount ||
          (p.todayViewCount == best.todayViewCount &&
              (p.createdAt.isAfter(best.createdAt) ||
                  (p.createdAt == best.createdAt && p.id.compareTo(best.id) < 0)))) {
        best = p;
      }
    }
    return best?.id;
  }
}
