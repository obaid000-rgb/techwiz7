import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/merchandise.dart';
import '../../services/auth_service.dart';
import '../../services/merchandise_service.dart';
import '../../services/wishlist_price_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/guest_prompt.dart';
import 'shop_tab.dart';

/// The signed-in fan's wishlisted products, shown with the same card and
/// grid as the Shop. Tapping a card's heart removes it from here directly.
/// Items whose price changed carry a "was $X" badge until the fan opens them.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // Subscribed once and held in state, so wishlist changes (which rebuild
  // this screen) never resubscribe or flash the loading state.
  StreamSubscription<List<Merchandise>>? _merchSub;
  List<Merchandise>? _merch;
  Object? _merchError;

  @override
  void initState() {
    super.initState();
    _merchSub = MerchandiseService.instance.watchMerchandise().listen(
      (m) {
        if (!mounted) return;
        setState(() {
          _merch = m;
          _merchError = null;
        });
      },
      onError: (Object e) {
        if (mounted) setState(() => _merchError = e);
      },
    );
    // Opening the Wishlist is one of the two price-check triggers.
    WishlistPriceService.instance.checkNow();
  }

  @override
  void dispose() {
    _merchSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Wishlist', style: AppTheme.orbitron(size: 13)),
      ),
      body: ValueListenableBuilder<UserData?>(
        valueListenable: AuthService.instance.userNotifier,
        builder: (context, user, _) {
          if (user == null) {
            return const GuestPrompt(feature: 'Your wishlist');
          }
          if (_merchError != null && _merch == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.grey, size: 28),
                  const SizedBox(height: 8),
                  Text('Could not load your wishlist',
                      style: AppTheme.inter(size: 12, color: Colors.grey)),
                ],
              ),
            );
          }
          if (_merch == null) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange),
            );
          }
          // Keep wishlist order (oldest first); IDs of products that
          // have since been deleted are simply skipped.
          final byId = {for (final m in _merch!) m.id: m};
          final items = [
            for (final id in user.wishlistedProductIds)
              if (byId[id] != null) byId[id]!,
          ];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border, color: Colors.grey, size: 36),
                    const SizedBox(height: 10),
                    Text('Your wishlist is empty',
                        style: AppTheme.orbitron(
                            size: 12, color: Colors.grey, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Browse the Shop and tap the heart on any product to add it.',
                        textAlign: TextAlign.center,
                        style: AppTheme.inter(size: 11, color: Colors.grey)),
                  ],
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: kMerchGridDelegate,
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final was = _comparePrice(item, user.wishlistPrices[item.id]);
              return MerchProductCard(
                key: ValueKey(item.id),
                item: item,
                badge: was == null ? null : _PriceChangeBadge(was: was, now: item.price),
                onOpen: was == null
                    ? null
                    : () => WishlistPriceService.instance.acknowledge(item.id),
              );
            },
          );
        },
      ),
    );
  }

  /// The earlier price to badge against, or null if nothing to show.
  /// Live price vs the stored baseline covers a change not yet processed
  /// by a check; otherwise the last detected change (previousPrice) stays
  /// badged until the fan opens the product — even if its notification
  /// was missed, dismissed, or notifications are off.
  static double? _comparePrice(Merchandise item, WishlistPrice? stored) {
    if (stored == null) return null;
    if (WishlistPriceService.differs(item.price, stored.lastSeenPrice)) {
      return stored.lastSeenPrice;
    }
    final prev = stored.previousPrice;
    if (prev != null && WishlistPriceService.differs(item.price, prev)) return prev;
    return null;
  }
}

class _PriceChangeBadge extends StatelessWidget {
  final double was;
  final double now;
  const _PriceChangeBadge({required this.was, required this.now});

  @override
  Widget build(BuildContext context) {
    final drop = now < was;
    final color = drop ? const Color(0xFF22C55E) : AppTheme.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(drop ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 12),
        const SizedBox(width: 3),
        Flexible(
          child: Text('Was ${WishlistPriceService.money(was)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.inter(size: 10, weight: FontWeight.w700, color: color)),
        ),
      ]),
    );
  }
}
