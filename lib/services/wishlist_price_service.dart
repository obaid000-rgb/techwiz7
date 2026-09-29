import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/merchandise.dart';
import 'auth_service.dart';
import 'firestore_db.dart';
import 'notification_service.dart';
import 'user_service.dart';

/// One detected wishlist price change.
class WishlistPriceChange {
  final String productId;
  final String name;
  final double oldPrice;
  final double newPrice;
  const WishlistPriceChange(this.productId, this.name, this.oldPrice, this.newPrice);
  bool get isDrop => newPrice < oldPrice;
}


class WishlistPriceService {
  static final WishlistPriceService instance = WishlistPriceService._();
  WishlistPriceService._();

  static const double _epsilon = 0.005; // prices are money: compare to the cent

  AppLifecycleListener? _lifecycle;
  String? _lastUid;
  Future<List<WishlistPriceChange>>? _inFlight;

  static String money(double v) => '\$${v.toStringAsFixed(2)}';

  static bool differs(double a, double b) => (a - b).abs() >= _epsilon;

  /// Call once at startup.
  void start() {
    if (_lifecycle != null) return;
    _lifecycle = AppLifecycleListener(onResume: () => checkNow());
    AuthService.instance.userNotifier.addListener(_onUserChanged);
    _onUserChanged();
  }

  void _onUserChanged() {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != null && uid != _lastUid) {
      _lastUid = uid;
      checkNow();
    }
    if (uid == null) _lastUid = null;
  }

  Future<List<WishlistPriceChange>> checkNow() {
    final existing = _inFlight;
    if (existing != null) return existing;
    Future<List<WishlistPriceChange>> run() async {
      try {
        return await _check();
      } finally {
        _inFlight = null;
      }
    }
    return _inFlight = run();
  }

  Future<List<WishlistPriceChange>> _check() async {
    final user = AuthService.instance.currentUser;
    if (user == null || user.wishlistedProductIds.isEmpty) return const [];
    try {
      final products = await _fetch(user.wishlistedProductIds);
      final updates = <String, WishlistPrice>{};
      final changes = <WishlistPriceChange>[];
      for (final id in user.wishlistedProductIds) {
        final product = products[id];
        if (product == null) continue; // deleted product: nothing to compare
        final stored = user.wishlistPrices[id];
        if (stored == null) {
    
          updates[id] = WishlistPrice(product.price);
        } else if (differs(product.price, stored.lastSeenPrice)) {
          updates[id] = WishlistPrice(product.price, stored.lastSeenPrice);
          changes.add(WishlistPriceChange(id, product.name, stored.lastSeenPrice, product.price));
        }
      }
      if (updates.isEmpty) {
        _log('checked ${products.length} item(s): no price changes');
        return const [];
      }

      try {
        await UserService.instance
            .setWishlistPrices(user.uid, updates)
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        _log('baseline write queued (offline?)');
      }
      final current = AuthService.instance.currentUser;
      if (current != null && current.uid == user.uid) {
        AuthService.instance.userNotifier.value = current.copyWith(
          wishlistPrices: {...current.wishlistPrices, ...updates},
        );
      }

      for (final c in changes) {
        _log('${c.name}: ${money(c.oldPrice)} -> ${money(c.newPrice)}');

        try {
          await NotificationService.instance.showPriceAlert(
            productId: c.productId,
            title: c.isDrop ? 'Price drop on your wishlist' : 'Price increase on your wishlist',
            body: 'Price for ${c.name} changed: was ${money(c.oldPrice)}, now ${money(c.newPrice)}',
          );
        } catch (e) {
          _log('notification failed for ${c.productId}: $e');
        }
      }
      return changes;
    } catch (e) {
      _log('check failed: $e');
      return const [];
    }
  }


  Future<void> acknowledge(String productId) async {
    final user = AuthService.instance.currentUser;
    final entry = user?.wishlistPrices[productId];
    if (user == null || entry == null || entry.previousPrice == null) return;
    final cleared = WishlistPrice(entry.lastSeenPrice);
    AuthService.instance.userNotifier.value =
        user.copyWith(wishlistPrices: {...user.wishlistPrices, productId: cleared});
    try {
      await UserService.instance.setWishlistPrices(user.uid, {productId: cleared});
    } catch (e) {
      _log('acknowledge failed: $e');
    }
  }

  Future<Map<String, Merchandise>> _fetch(List<String> ids) async {
    final out = <String, Merchandise>{};
    // whereIn accepts at most 30 values per query.
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snap = await FirestoreDb.instance
          .collection('merchandise')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        out[d.id] = Merchandise.fromMap(d.data(), d.id);
      }
    }
    return out;
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[PriceWatch] $msg');
  }
}
