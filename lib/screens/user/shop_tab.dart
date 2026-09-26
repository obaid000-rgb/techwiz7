import 'package:flutter/material.dart';
import '../../models/merchandise.dart';
import '../../services/auth_service.dart';
import '../../services/merchandise_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/guest_prompt.dart';
import '../../widgets/section_header.dart';
import 'wishlist_screen.dart';

/// Merchandise grid, moved here from the old ExploreTab (which was
/// repurposed into the Explore/Lore landing page).
class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(
                  icon: Icons.shopping_bag,
                  iconColor: AppTheme.orange,
                  title: 'OFFICIAL MERCHANDISE',
                ),
              ),
              _wishlistButton(context),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Merchandise>>(
            stream: MerchandiseService.instance.watchMerchandise(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.grey, size: 28),
                        const SizedBox(height: 8),
                        Text('Could not load merchandise',
                            style: AppTheme.inter(size: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              final merch = snapshot.data ?? [];
              if (merch.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 36),
                        const SizedBox(height: 10),
                        Text('No merchandise available',
                            style: AppTheme.orbitron(
                                size: 12, color: Colors.grey, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Official merchandise will appear here when listed.',
                            style: AppTheme.inter(size: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: kMerchGridDelegate,
                itemCount: merch.length,
                itemBuilder: (context, idx) => MerchProductCard(item: merch[idx]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _wishlistButton(BuildContext context) =>
      ValueListenableBuilder<UserData?>(
        valueListenable: AuthService.instance.userNotifier,
        builder: (context, user, _) {
          final count = user?.wishlistedProductIds.length ?? 0;
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WishlistScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.orange.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: AppTheme.orange, size: 14),
                  const SizedBox(width: 5),
                  Text(count > 0 ? 'Wishlist ($count)' : 'Wishlist',
                      style: AppTheme.inter(
                          size: 11, color: AppTheme.orange, weight: FontWeight.w600)),
                ],
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
  childAspectRatio: 0.68,
);

/// Adds or removes [item] from the signed-in user's wishlist. Guests get the
/// standard [GuestPrompt] instead. The heart flips immediately; if the
/// Firestore write fails it flips back and a snackbar explains why.
Future<void> toggleWishlist(BuildContext context, Merchandise item) async {
  final user = AuthService.instance.currentUser;
  if (user == null) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _WishlistLoginSheet(),
    );
    return;
  }
  final wasWishlisted = user.wishlistedProductIds.contains(item.id);
  final ids = List<String>.from(user.wishlistedProductIds);
  wasWishlisted ? ids.remove(item.id) : ids.add(item.id);
  AuthService.instance.userNotifier.value =
      user.copyWith(wishlistedProductIds: ids);
  try {
    await UserService.instance.setWishlisted(user.uid, item.id, !wasWishlisted);
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

/// Hosts the existing [GuestPrompt] in a sheet, and closes itself once the
/// guest signs in or registers from it (so they land back on the Shop).
class _WishlistLoginSheet extends StatefulWidget {
  const _WishlistLoginSheet();

  @override
  State<_WishlistLoginSheet> createState() => _WishlistLoginSheetState();
}

class _WishlistLoginSheetState extends State<_WishlistLoginSheet> {
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
      const SafeArea(child: GuestPrompt(feature: 'Your wishlist'));
}

/// Product card used by the Shop grid and the Wishlist screen.
class MerchProductCard extends StatelessWidget {
  final Merchandise item;
  const MerchProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isWishlisted
                                ? AppTheme.orange
                                : Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: isWishlisted ? Colors.black : Colors.white,
                            size: 16,
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
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(size: 12, weight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: AppTheme.orbitron(size: 13, color: AppTheme.orange, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${item.name} added to cart!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      '+ Cart',
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
