import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/fandom.dart';
import '../utils/fandom_stats.dart';
import 'firestore_db.dart';

class FandomException implements Exception {
  final String message;
  const FandomException(this.message);

  @override
  String toString() => message;
}

class FandomService {
  static final FandomService instance = FandomService._();
  FandomService._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreDb.instance.collection('fandoms');

  List<Fandom> _sorted(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => Fandom.fromMap(d.data(), d.id)).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Stream<List<Fandom>> watchAll() => _col.snapshots().map(_sorted);

  Future<List<Fandom>> getAll() async => _sorted(await _col.get());

  Future<List<Fandom>> getAllActive() async =>
      (await getAll()).where((f) => f.isActive).toList();

  Future<List<Fandom>> getByCategory(
    String categoryId, {
    bool includeInactive = false,
  }) async {
    final list = _sorted(
      await _col.where('categoryId', isEqualTo: categoryId).get(),
    );
    return includeInactive ? list : list.where((f) => f.isActive).toList();
  }

  Future<Fandom?> getById(String id) async {
    final doc = await _col.doc(id).get();
    final data = doc.data();
    return data == null ? null : Fandom.fromMap(data, doc.id);
  }

  Stream<Fandom?> watchById(String id) => _col.doc(id).snapshots().map((d) {
        final data = d.data();
        return data == null ? null : Fandom.fromMap(data, d.id);
      });

  Stream<List<Fandom>> watchTrending({
    int limit = 8,
    bool fallbackToMostFollowed = true,
  }) =>
      _col.snapshots().map((s) => rankTrendingFandoms(
            _sorted(s),
            DateTime.now(),
            limit: limit,
            fallbackToMostFollowed: fallbackToMostFollowed,
          ));

  static final Set<String> _viewedThisSession = {};

  @visibleForTesting
  static void resetSessionViews() => _viewedThisSession.clear();

  // Fandom page view (signed-in fans; the caller checks). Counted at most
  // once per fandom per app session. One transaction:
  //  - Week reset: if the stored weekKey is the current ISO week, the
  //    weekly view counter goes up by 1. Otherwise the stored weekly
  //    numbers belong to an older week, so this view starts a fresh week:
  //    weekViewCount = 1, weekFollowCount = 0, weekKey = this week.
  //  - The all-time viewCount goes up by 1 either way.
  // Increments use FieldValue.increment so concurrent fans each add
  // exactly 1, which is what the fandoms rule allows.
  Future<void> recordView(String fandomId) async {
    if (!_viewedThisSession.add(fandomId)) return;
    final ref = _col.doc(fandomId);
    final week = isoWeekKey(DateTime.now());
    try {
      await FirestoreDb.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) return;
        tx.update(
          ref,
          data['weekKey'] == week
              ? {
                  'weekViewCount': FieldValue.increment(1),
                  'viewCount': FieldValue.increment(1),
                }
              : {
                  'weekViewCount': 1,
                  'weekFollowCount': 0,
                  'weekKey': week,
                  'viewCount': FieldValue.increment(1),
                },
        );
      });
    } catch (_) {
      _viewedThisSession.remove(fandomId);
      rethrow;
    }
  }

  Future<List<Fandom>> getByIds(List<String> ids) async {
    final unique = ids.toSet().toList();
    final out = <Fandom>[];
    for (var i = 0; i < unique.length; i += 10) {
      final chunk = unique.sublist(i, i + 10 > unique.length ? unique.length : i + 10);
      final s =
          await _col.where(FieldPath.documentId, whereIn: chunk).get();
      out.addAll(s.docs.map((d) => Fandom.fromMap(d.data(), d.id)));
    }
    return out;
  }

  Stream<List<Fandom>> watchByIds(List<String> ids) => _col
      .where(FieldPath.documentId, whereIn: ids.take(maxFollowed).toList())
      .snapshots()
      .map(_sorted);

  static const int maxFollowed = 30;

  // Follow / unfollow run as ONE transaction over both documents: the fan's
  // users/{uid}.followedFandomIds and the fandom's followerCount always
  // change together or not at all. The transaction reads the fan's list
  // first, so a repeat follow (double tap, second device) or an unfollow of
  // something not followed is a no-op that never touches the count. The
  // count moves with FieldValue.increment(±1) rather than a computed value:
  // the server applies it to whatever is stored at commit time, which is
  // exactly the "+1 or -1 from the stored value" the security rule checks,
  // so concurrent fans can never be rejected for a stale count.
  Future<void> follow(String uid, String fandomId) {
    final db = FirestoreDb.instance;
    final userRef = db.collection('users').doc(uid);
    final fandomRef = _col.doc(fandomId);
    return db.runTransaction((tx) async {
      final user = await tx.get(userRef);
      final fandom = await tx.get(fandomRef);
      final ids = _followedIn(user.data());
      if (ids.contains(fandomId)) return;
      final data = fandom.data();
      if (data == null || data['isActive'] == false) {
        throw const FandomException('This fandom isn\'t available.');
      }
      if (ids.length >= maxFollowed) {
        throw const FandomException('You can follow up to 30 fandoms.');
      }
      tx.update(userRef, {
        'followedFandomIds': FieldValue.arrayUnion([fandomId]),
      });
      // Trending: a follow also counts toward this week, with the same
      // week-reset rule as page views — same week: weekFollowCount + 1;
      // older (or missing) week: start this week at 1 follow, 0 views.
      final week = isoWeekKey(DateTime.now());
      tx.update(fandomRef, {
        'followerCount': FieldValue.increment(1),
        if (data['weekKey'] == week)
          'weekFollowCount': FieldValue.increment(1)
        else ...{
          'weekFollowCount': 1,
          'weekViewCount': 0,
          'weekKey': week,
        },
      });
    });
  }

  Future<void> unfollow(String uid, String fandomId) {
    final db = FirestoreDb.instance;
    final userRef = db.collection('users').doc(uid);
    final fandomRef = _col.doc(fandomId);
    return db.runTransaction((tx) async {
      final user = await tx.get(userRef);
      final fandom = await tx.get(fandomRef);
      if (!_followedIn(user.data()).contains(fandomId)) return;
      tx.update(userRef, {
        'followedFandomIds': FieldValue.arrayRemove([fandomId]),
      });
      final data = fandom.data();
      final count = data?['followerCount'];
      final weekFollows = data?['weekFollowCount'];
      // Unfollow takes back this week's follow point only when that point
      // was earned THIS week (weekKey is current) and is still above 0, so
      // following and unfollowing repeatedly nets to zero and can never
      // push the weekly score up — or below 0.
      final undoWeekFollow = data?['weekKey'] == isoWeekKey(DateTime.now()) &&
          weekFollows is num &&
          weekFollows > 0;
      final changes = <String, Object>{
        if (count is num && count > 0) 'followerCount': FieldValue.increment(-1),
        if (undoWeekFollow) 'weekFollowCount': FieldValue.increment(-1),
      };
      if (changes.isNotEmpty) tx.update(fandomRef, changes);
    });
  }

  List<String> _followedIn(Map<String, dynamic>? userData) {
    final raw = userData?['followedFandomIds'];
    return raw is List ? raw.whereType<String>().toList() : const [];
  }

  Future<bool> nameExists(String name, {String? excludeId}) async {
    final normalized = name.trim().toLowerCase();
    final s = await _col.get();
    return s.docs.any(
      (d) =>
          d.id != excludeId &&
          (d.data()['name'] as String? ?? '').trim().toLowerCase() ==
              normalized,
    );
  }

  Future<String> create(Fandom fandom) async {
    final name = fandom.name.trim();
    final id = Fandom.slugFor(name);
    if (id.isEmpty) {
      throw const FandomException('The name must contain letters or numbers.');
    }
    if (await nameExists(name)) {
      throw FandomException('A fandom named "$name" already exists.');
    }
    final created = await _createIfAbsent(id, fandom.copyWith(name: name));
    if (!created) {
      throw FandomException(
        'A fandom with the ID "$id" already exists. Choose a different name.',
      );
    }
    return id;
  }

  Future<bool> createIfAbsent(Fandom fandom) =>
      _createIfAbsent(Fandom.slugFor(fandom.name), fandom);

  Future<bool> _createIfAbsent(String id, Fandom fandom) =>
      FirestoreDb.instance.runTransaction((tx) async {
        final ref = _col.doc(id);
        if ((await tx.get(ref)).exists) return false;
        tx.set(ref, {
          ...fandom.toMap(),
          'followerCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      });

  Future<void> update(Fandom fandom) async {
    final name = fandom.name.trim();
    if (name.isEmpty) {
      throw const FandomException('Name is required.');
    }
    if (await nameExists(name, excludeId: fandom.id)) {
      throw FandomException('A fandom named "$name" already exists.');
    }
    final data = fandom.copyWith(name: name).toMap()
      ..remove('followerCount')
      ..remove('createdAt')
      ..remove('viewCount')
      ..remove('weekViewCount')
      ..remove('weekFollowCount')
      ..remove('weekKey');
    final before = await getById(fandom.id);
    final renamed = before != null && before.name != name;
    final moved = before != null && before.categoryId != fandom.categoryId;

    final db = FirestoreDb.instance;
    final batch = db.batch();
    batch.update(_col.doc(fandom.id), data);
    if (renamed || moved) {
      final posts = await db
          .collection('posts')
          .where('fandomId', isEqualTo: fandom.id)
          .get();
      for (final p in posts.docs) {
        batch.update(p.reference, {
          // Fandom renamed: copy the new name into the denormalized
          // fandomName of every post in this fandom, in the same batch as
          // the fandom itself.
          if (renamed) 'fandomName': name,
          // Fandom moved to another category: move its posts too, so every
          // category-based query (Home, Explore, Category Detail) follows it.
          if (moved) 'category': fandom.categoryId,
        });
      }
      final merch = await db
          .collection('merchandise')
          .where('fandomId', isEqualTo: fandom.id)
          .get();
      for (final m in merch.docs) {
        batch.update(m.reference, {
          // Fandom renamed: the fandom's products carry the new fandomName
          // too, written in the same batch as the fandom and its posts.
          if (renamed) 'fandomName': name,
          // Fandom moved to another category: its products move with it, so
          // Shop's category browsing still lists them under the right one.
          if (moved) 'category': fandom.categoryId,
        });
      }
    }
    await batch.commit();
  }

  Future<Map<String, int>> postCounts(String fandomId) async {
    final posts = await FirestoreDb.instance
        .collection('posts')
        .where('fandomId', isEqualTo: fandomId)
        .get();
    final active = posts.docs.where(
      (d) => (d.data()['status'] ?? 'active') == 'active',
    );
    return {'total': posts.docs.length, 'active': active.length};
  }

  Future<void> softDelete(String id) =>
      _col.doc(id).update({'isActive': false});

  Future<void> restore(String id) => _col.doc(id).update({'isActive': true});
}
