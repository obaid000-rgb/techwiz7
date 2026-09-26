import 'package:flutter/material.dart';
import '../../models/merchandise.dart';
import '../../services/auth_service.dart';
import '../../services/merchandise_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/guest_prompt.dart';
import 'shop_tab.dart';

/// The signed-in fan's wishlisted products, shown with the same card and
/// grid as the Shop. Tapping a card's heart removes it from here directly.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // Created once so wishlist changes (which rebuild this screen) don't
  // resubscribe and flash the loading state.
  late final Stream<List<Merchandise>> _merchStream =
      MerchandiseService.instance.watchMerchandise();

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
          return StreamBuilder<List<Merchandise>>(
            stream: _merchStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange),
                );
              }
              if (snapshot.hasError) {
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
              // Keep wishlist order (oldest first); IDs of products that
              // have since been deleted are simply skipped.
              final byId = {for (final m in snapshot.data ?? <Merchandise>[]) m.id: m};
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
                itemBuilder: (context, i) =>
                    MerchProductCard(key: ValueKey(items[i].id), item: items[i]),
              );
            },
          );
        },
      ),
    );
  }
}
