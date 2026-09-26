import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../models/merchandise.dart';
import '../../services/auth_service.dart';
import '../../services/category_service.dart';
import '../../theme/app_theme.dart';
import 'cart_screen.dart';
import 'shop_tab.dart';

class ProductDetailScreen extends StatefulWidget {
  final Merchandise item;
  const ProductDetailScreen({super.key, required this.item});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final Future<List<AppCategory>> _categories =
      CategoryService.instance.fetchCategories();
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppTheme.card,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              _wishlistButton(),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _categoryChip(item.category),
                  const SizedBox(height: 12),
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('\$${item.price.toStringAsFixed(2)}',
                      style: AppTheme.orbitron(
                          size: 20, color: AppTheme.orange, weight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  Text('DESCRIPTION',
                      style: AppTheme.orbitron(
                          size: 10, color: Colors.grey, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Text(
                    item.description.isEmpty
                        ? 'No description available for this product.'
                        : item.description,
                    style: AppTheme.inter(
                        size: 13,
                        color: item.description.isEmpty ? Colors.grey : Colors.white70,
                        height: 1.55),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('QUANTITY',
                          style: AppTheme.orbitron(
                              size: 10, color: Colors.grey, letterSpacing: 0.8)),
                      const Spacer(),
                      _stepper(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerRight, child: CartButton()),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton.icon(
            onPressed: () => addToCart(context, item, quantity: _quantity),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_shopping_cart, color: Colors.black, size: 18),
            label: Text(
                'ADD TO CART · \$${(item.price * _quantity).toStringAsFixed(2)}',
                style: AppTheme.orbitron(size: 11, color: Colors.black, weight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  Widget _wishlistButton() => ValueListenableBuilder<UserData?>(
        valueListenable: AuthService.instance.userNotifier,
        builder: (context, user, _) {
          final isWishlisted =
              user?.wishlistedProductIds.contains(widget.item.id) ?? false;
          return GestureDetector(
            onTap: () => toggleWishlist(context, widget.item),
            child: Container(
              padding: const EdgeInsets.all(8),
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
      );

  Widget _categoryChip(String key) {
    if (key.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<AppCategory>>(
      future: _categories,
      builder: (context, snap) {
        final matches = (snap.data ?? []).where((c) => c.key == key);
        final label = matches.isEmpty ? key : matches.first.name;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.orange.withValues(alpha: 0.5)),
          ),
          child: Text(label.toUpperCase(),
              style: AppTheme.inter(size: 10, color: AppTheme.orange, weight: FontWeight.w700)),
        );
      },
    );
  }

  Widget _stepper() => Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              color: AppTheme.orange,
              disabledColor: Colors.white24,
              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
            ),
            Text('$_quantity', style: AppTheme.orbitron(size: 14, weight: FontWeight.w700)),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              color: AppTheme.orange,
              disabledColor: Colors.white24,
              onPressed: _quantity < 99 ? () => setState(() => _quantity++) : null,
            ),
          ],
        ),
      );

  Widget _imageFallback() => Container(
        color: AppTheme.card,
        alignment: Alignment.center,
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 56),
      );
}
