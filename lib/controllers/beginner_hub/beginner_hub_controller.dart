import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/glossary_term.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/first_run_service.dart';
import '../../services/firestore_db.dart';

class HubStep {
  final String title;
  final String subtitle;
  final bool done;
  const HubStep(this.title, this.subtitle, this.done);
}

class BeginnerHubController {
  const BeginnerHubController();

  static const String readGuideKey = 'hubReadBeginnerGuide';
  static const String openedGlossaryKey = 'hubOpenedGlossary';

  static Future<Box> openFlags() => Hive.openBox(FirstRunService.boxName);

  static void markBeginnerGuideRead() => _setFlag(readGuideKey);

  static void markGlossaryOpened() => _setFlag(openedGlossaryKey);

  static const String homeCardDismissedKey = 'hubHomeCardDismissed';

  static void dismissHomeCard() => _setFlag(homeCardDismissedKey);

  static Future<void> _setFlag(String key) async {
    try {
      final box = await openFlags();
      if (box.get(key) != true) await box.put(key, true);
    } catch (e) {
      debugPrint('Hub progress flag failed: $e');
    }
  }

  // Checklist completion: "Follow a fandom" is done only for a signed-in
  // fan following at least one fandom (guests always see it open). The
  // other two steps come from on-device flags that the Content Detail
  // screen (beginner posts only) and the Glossary screen set when opened.
  // All three done → the Hub shows "You're all set" instead of the list.
  List<HubStep> checklist(UserData? user, Box? flags) => [
        HubStep('Follow a fandom', 'Get their posts on your Home feed',
            (user?.followedFandomIds.isNotEmpty ?? false)),
        HubStep('Read a beginner guide', 'No prior knowledge needed',
            flags?.get(readGuideKey) == true),
        HubStep('Learn the lingo', 'Open the Fandom Glossary',
            flags?.get(openedGlossaryKey) == true),
      ];

  bool allDone(List<HubStep> steps) => steps.every((s) => s.done);

  Stream<List<Post>> beginnerPosts() => FirestoreDb.instance
      .collection('posts')
      .where('contentDepth', isEqualTo: 'beginner')
      .snapshots()
      .map((s) => s.docs
          .map((d) => Post.fromMap(d.data(), d.id))
          .where((p) => p.isActive)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  List<Post> rankBeginnerPosts(List<Post> posts,
      {List<String> followedFandomIds = const [],
      List<String> interestCategories = const []}) {
    final followed = followedFandomIds.toSet();
    final interests = interestCategories.toSet();
    int group(Post p) {
      if (p.hasFandom && followed.contains(p.fandomId)) return 0;
      if (interests.contains(p.category)) return 1;
      return 2;
    }

    return List<Post>.from(posts)
      ..sort((a, b) {
        final g = group(a).compareTo(group(b));
        return g != 0 ? g : b.createdAt.compareTo(a.createdAt);
      });
  }

  List<GlossaryTerm> alphabetical(List<GlossaryTerm> terms) =>
      List<GlossaryTerm>.from(terms)
        ..sort((a, b) {
          final byTerm = a.term.toLowerCase().compareTo(b.term.toLowerCase());
          return byTerm != 0 ? byTerm : a.id.compareTo(b.id);
        });

  // Term of the day: the terms are put in a fixed alphabetical order, then
  // the day of the year (1–366, from the device's local date) modulo the
  // number of terms picks one. Every fan sees the same term all day, it
  // survives app restarts, and it moves on to the next term at midnight.
  GlossaryTerm? termOfTheDay(List<GlossaryTerm> terms, DateTime now) {
    if (terms.isEmpty) return null;
    final sorted = alphabetical(terms);
    final today = DateTime(now.year, now.month, now.day);
    final dayOfYear = today.difference(DateTime(now.year)).inDays + 1;
    return sorted[dayOfYear % sorted.length];
  }

  List<GlossaryTerm> moreTerms(List<GlossaryTerm> terms, GlossaryTerm today,
      {int count = 3}) {
    final sorted = alphabetical(terms);
    final start = sorted.indexWhere((t) => t.id == today.id);
    return [
      for (var i = 1; i <= count && i < sorted.length; i++)
        sorted[(start + i) % sorted.length],
    ]..sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
  }
}
