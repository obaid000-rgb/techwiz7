import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../models/merchandise.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/category_service.dart';
import '../../services/merchandise_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/guest_prompt.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'wishlist_screen.dart';

enum _PriceSort { featured, lowToHigh, highToLow }

/// Shop tab: official merchandise grid with category filtering, price
/// sorting, and wishlist and cart entry points.
class ShopTab extends StatefulWidget {
  const ShopTab({super.key});

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  // Subscribed once and held in state (not a StreamBuilder created in
  // build), so rebuilds never resubscribe or lose the latest snapshot.
  StreamSubscription<List<Merchandise>>? _merchSub;
  StreamSubscription<List<AppCategory>>? _catSub;
  List<Merchandise>? _merch;
  Object? _merchError;
  Map<String, AppCategory> _categories = const {};

  String? _category; // null = All
  _PriceSort _sort = _PriceSort.featured;

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
        debugPrint('Merchandise load error: $e');
        if (mounted) setState(() => _merchError = e);
      },
    );
    // Category names only label the filter chips; if they fail to load,
    // chips fall back to the raw category key.
    _catSub = CategoryService.instance.watchCategories().listen(
      (cats) {
        if (mounted) setState(() => _categories = {for (final c in cats) c.key: c});
      },
      onError: (Object e) => debugPrint('Category load error: $e'),
    );
  }

  @override
  void dispose() {
    _merchSub?.cancel();
    _catSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shop', style: AppTheme.orbitron(size: 22, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Official fandom merchandise.',
                      style: AppTheme.inter(size: 14, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const CartButton(),
          ],
        ),
        const SizedBox(height: 16),
        _wishlistButton(context),
        const SizedBox(height: 16),
        _catalog(),
      ],
    );
  }

  Widget _catalog() {
    if (_merchError != null && _merch == null) {
      return _message(Icons.wifi_off, 'Could not load products',
          'Check your connection and try again.');
    }
    final merch = _merch;
    if (merch == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange)),
      );
    }
    if (merch.isEmpty) {
      return _message(Icons.shopping_bag_outlined, 'No products yet',
          'Official merchandise will appear here when listed.');
    }

    // Chips come from the categories products actually use, in the admin's
    // category order; keys with no category doc go last, labelled by key.
    final keys = {
      for (final m in merch)
        if (m.category.trim().isNotEmpty) m.category,
    }.toList()
      ..sort((a, b) {
        final oa = _categories[a]?.order ?? 1 << 30;
        final ob = _categories[b]?.order ?? 1 << 30;
        return oa != ob ? oa.compareTo(ob) : _label(a).compareTo(_label(b));
      });
    // A selected category whose products were all removed falls back to All.
    final selected = keys.contains(_category) ? _category : null;

    final shown = [
      for (final m in merch)
        if (selected == null || m.category == selected) m,
    ];
    switch (_sort) {
      case _PriceSort.featured:
        break; // catalog order, as before
      case _PriceSort.lowToHigh:
        shown.sort((a, b) => a.price.compareTo(b.price));
      case _PriceSort.highToLow:
        shown.sort((a, b) => b.price.compareTo(a.price));
    }
    final countLabel = '${shown.length} product${shown.length == 1 ? '' : 's'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip('All', selected == null, () => setState(() => _category = null)),
              for (final k in keys)
                _chip(_label(k), selected == k, () => setState(() => _category = k)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Text(countLabel, style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
          ),
          _sortMenu(),
        ]),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          _message(Icons.filter_alt_off_outlined, 'No products in this category',
              'Try another category or tap All.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: kMerchGridDelegate,
            itemCount: shown.length,
            itemBuilder: (context, idx) =>
                MerchProductCard(key: ValueKey(shown[idx].id), item: shown[idx]),
          ),
      ],
    );
  }

  String _label(String key) {
    final name = _categories[key]?.name ?? '';
    return name.isNotEmpty ? name : key;
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          labelStyle: AppTheme.inter(
              size: 12,
              weight: FontWeight.w600,
              color: selected ? Colors.black : AppTheme.textSecondary),
          selectedColor: AppTheme.orange,
          backgroundColor: AppTheme.card,
          side: BorderSide(color: selected ? AppTheme.orange : AppTheme.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      );

  static const Map<_PriceSort, String> _sortLabels = {
    _PriceSort.featured: 'Featured',
    _PriceSort.lowToHigh: 'Price: Low to High',
    _PriceSort.highToLow: 'Price: High to Low',
  };

  Widget _sortMenu() => PopupMenuButton<_PriceSort>(
        initialValue: _sort,
        color: AppTheme.card,
        tooltip: 'Sort products',
        onSelected: (s) => setState(() => _sort = s),
        itemBuilder: (_) => [
          for (final e in _sortLabels.entries)
            PopupMenuItem(
              value: e.key,
              child: Text(e.value,
                  style: AppTheme.inter(
                      size: 13, color: e.key == _sort ? AppTheme.orange : Colors.white)),
            ),
        ],
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.swap_vert, size: 18, color: AppTheme.orange),
          const SizedBox(width: 4),
          Text(_sortLabels[_sort]!,
              style: AppTheme.inter(size: 12, weight: FontWeight.w600, color: AppTheme.orange)),
        ]),
      );

  Widget _message(IconData icon, String title, String subtitle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(icon, color: AppTheme.textMuted, size: 36),
          const SizedBox(height: 10),
          Text(title, style: AppTheme.inter(size: 15, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
        ]),
      );

  Widget _wishlistButton(BuildContext context) =>
      ValueListenableBuilder<UserData?>(
        valueListenable: AuthService.instance.userNotifier,
        builder: (context, user, _) {
          final count = user?.wishlistedProductIds.length ?? 0;
          return Material(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistScreen()),
              ),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(children: [
                  const Icon(Icons.favorite, color: AppTheme.pink, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('My wishlist',
                        style: AppTheme.inter(size: 14, weight: FontWeight.w500)),
                  ),
                  Text(count == 0 ? 'Empty' : '$count item${count == 1 ? '' : 's'}',
                      style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                ]),
              ),
            ),
          );
        },
      );
}

/// Shop grid layout, shared with [WishlistScreen] so both grids match.
const SliverGridDelegateWithFixedCrossAxisCount kMerchGridDelegate =
    SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: 0.62,
);

/// Adds or removes [item] from the signed-in user's wishlist. Guests get the
/// standard [GuestPrompt] instead. The heart flips immediately; if the
/// Firestore write fails it flips back and a snackbar explains why.
Future<void> toggleWishlist(BuildContext context, Merchandise item) async {
  final user = AuthService.instance.currentUser;
  if (user == null) {
    showGuestLoginSheet(context, feature: 'Your wishlist');
    return;
  }
  final wasWishlisted = user.wishlistedProductIds.contains(item.id);
  final ids = List<String>.from(user.wishlistedProductIds);
  wasWishlisted ? ids.remove(item.id) : ids.add(item.id);
  // Adding records the price right now as the baseline for price alerts.
  final prices = Map<String, WishlistPrice>.from(user.wishlistPrices);
  wasWishlisted ? prices.remove(item.id) : prices[item.id] = WishlistPrice(item.price);
  AuthService.instance.userNotifier.value =
      user.copyWith(wishlistedProductIds: ids, wishlistPrices: prices);
  try {
    await UserService.instance
        .setWishlisted(user.uid, item.id, !wasWishlisted, price: item.price);
  } catch (_) {
    final current = AuthService.instance.currentUser;
    if (current != null && current.uid == user.uid) {
      final reverted = List<String>.from(current.wishlistedProductIds);
      wasWishlisted ? reverted.add(item.id) : reverted.remove(item.id);
      AuthService.instance.userNotifier.value =
          current.copyWith(wishlistedProductIds: reverted.toSet().toList());
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your wishlist. Try again.')),
      );
    }
  }
}

/// Shows the standard [GuestPrompt] in a bottom sheet for a guest who tried a
/// signed-in-only Shop action (wishlist, cart).
void showGuestLoginSheet(BuildContext context, {required String feature}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _GuestLoginSheet(feature: feature),
  );
}

/// Adds [item] to the signed-in user's cart (guests get [GuestPrompt]).
Future<void> addToCart(BuildContext context, Merchandise item,
    {int quantity = 1}) async {
  final user = AuthService.instance.currentUser;
  if (user == null) {
    showGuestLoginSheet(context, feature: 'Your cart');
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  try {
    await CartService.instance.addToCart(user.uid, item, quantity: quantity);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(quantity > 1
          ? 'Added $quantity × ${item.name} to your cart'
          : '${item.name} added to your cart'),
      action: SnackBarAction(
        label: 'VIEW CART',
        textColor: AppTheme.orange,
        onPressed: () => navigator.push(
          MaterialPageRoute(builder: (_) => const CartScreen()),
        ),
      ),
    ));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not add to cart. Try again.')),
    );
  }
}

/// Hosts the existing [GuestPrompt] in a sheet, and closes itself once the
/// guest signs in or registers from it (so they land back on the Shop).
class _GuestLoginSheet extends StatefulWidget {
  final String feature;
  const _GuestLoginSheet({required this.feature});

  @override
  State<_GuestLoginSheet> createState() => _GuestLoginSheetState();
}

class _GuestLoginSheetState extends State<_GuestLoginSheet> {
  @override
  void initState() {
    super.initState();
    AuthService.instance.userNotifier.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.instance.userNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!AuthService.instance.isLoggedIn || !mounted) return;
    final route = ModalRoute.of(context);
    // removeRoute, not pop: the Login/Signup screen may still be on top.
    if (route != null && route.isActive) Navigator.of(context).removeRoute(route);
  }

  @override
  Widget build(BuildContext context) =>
      SafeArea(child: GuestPrompt(feature: widget.feature));
}

/// Product card used by the Shop grid and the Wishlist screen.
class MerchProductCard extends StatelessWidget {
  final Merchandise item;
  /// Optional overlay in the image's top-left corner (Wishlist price badge).
  final Widget? badge;
  /// Called when the card is tapped, before Product Detail opens.
  final VoidCallback? onOpen;
  const MerchProductCard({super.key, required this.item, this.badge, this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onOpen?.call();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(item: item)),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, st) => Container(
                            color: AppTheme.bg,
                            alignment: Alignment.center,
                            child: const Icon(Icons.shopping_bag_outlined,
                                color: Colors.white24, size: 36),
                          ),
                        )
                      : Container(
                          color: AppTheme.bg,
                          alignment: Alignment.center,
                          child: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.white24, size: 36),
                        ),
                ),
                if (badge != null) Positioned(top: 8, left: 8, right: 52, child: Align(
                  alignment: Alignment.topLeft,
                  child: badge!,
                )),
                // Same circle-button pattern as the bookmark on Home cards.
                Positioned(
                  top: 4,
                  right: 4,
                  child: ValueListenableBuilder<UserData?>(
                    valueListenable: AuthService.instance.userNotifier,
                    builder: (context, user, _) {
                      final isWishlisted =
                          user?.wishlistedProductIds.contains(item.id) ?? false;
                      return GestureDetector(
                        onTap: () => toggleWishlist(context, item),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: isWishlisted
                                ? AppTheme.orange
                                : Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: isWishlisted ? Colors.black : Colors.white,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(size: 13, weight: FontWeight.w600, color: Colors.white, height: 1.3),
                ),
                const SizedBox(height: 3),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: AppTheme.inter(size: 15, color: AppTheme.orange, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => addToCart(context, item),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text('Add to cart',
                        style: AppTheme.inter(size: 13, weight: FontWeight.w600, color: AppTheme.orange)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
