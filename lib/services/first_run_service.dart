import 'package:hive_ce_flutter/hive_flutter.dart';

class PendingSelection {
  final List<String> categories;
  final String badge;
  const PendingSelection(this.categories, this.badge);
}

/// On-device first-run state (Hive box `app_prefs`): whether the intro
/// sequence (slides + interest selection) was completed on this install, and
/// the interest/badge selection made before any account existed.
class FirstRunService {
  static const String boxName = 'app_prefs';
  static const String _seenKey = 'hasSeenOnboarding';
  static const String _pendingCategoriesKey = 'pendingCategories';
  static const String _pendingBadgeKey = 'pendingBadge';

  static final FirstRunService instance = FirstRunService._();
  FirstRunService._();

  Future<Box> _box() => Hive.openBox(boxName);

  Future<bool> hasSeenOnboarding() async =>
      (await _box()).get(_seenKey) == true;

  /// Stores the pre-login selection and marks the first-run sequence done.
  Future<void> completeOnboarding(List<String> categories, String badge) async {
    final box = await _box();
    await box.put(_pendingCategoriesKey, categories);
    await box.put(_pendingBadgeKey, badge);
    await box.put(_seenKey, true);
  }

  Future<PendingSelection?> readPending() async {
    final box = await _box();
    final cats = box.get(_pendingCategoriesKey);
    final badge = box.get(_pendingBadgeKey);
    if (cats is! List || cats.isEmpty || badge is! String || badge.isEmpty) {
      return null;
    }
    return PendingSelection(List<String>.from(cats), badge);
  }

  Future<void> clearPending() async {
    final box = await _box();
    await box.delete(_pendingCategoriesKey);
    await box.delete(_pendingBadgeKey);
  }
}
