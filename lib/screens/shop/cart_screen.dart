import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/guest_prompt.dart';
import 'checkout_screen.dart';

/// "Cart (n)" pill that opens [CartScreen]. Count is live per signed-in user.
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserData?>(
      valueListenable: AuthService.instance.userNotifier,
      builder: (context, user, _) => _CartCount(
        key: ValueKey(user?.uid),
        uid: user?.uid,
      ),
    );
  }
}

class _CartCount extends StatefulWidget {
  final String? uid;
  const _CartCount({super.key, required this.uid});

  @override
  State<_CartCount> createState() => _CartCountState();
}

class _CartCountState extends State<_CartCount> {
  late final Stream<List<CartItem>>? _stream =
      widget.uid == null ? null : CartService.instance.watchCart(widget.uid!);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CartItem>>(
      stream: _stream,
      builder: (context, snap) {
        final count = (snap.data ?? []).fold<int>(0, (acc, i) => acc + i.quantity);
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_bag_outlined, color: AppTheme.orange, size: 20),
                const SizedBox(width: 6),
                Text(count > 0 ? 'Cart · $count' : 'Cart',
                    style: AppTheme.inter(
                        size: 13, color: Colors.white, weight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

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
        title: Text('My Cart', style: AppTheme.orbitron(size: 13)),
      ),
      body: ValueListenableBuilder<UserData?>(
        valueListenable: AuthService.instance.userNotifier,
        builder: (context, user, _) {
          if (user == null) return const GuestPrompt(feature: 'Your cart');
          return _CartBody(key: ValueKey(user.uid), uid: user.uid);
        },
      ),
    );
  }
}

class _CartBody extends StatefulWidget {
  final String uid;
  const _CartBody({super.key, required this.uid});

  @override
  State<_CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<_CartBody> {
  late final Stream<List<CartItem>> _stream =
      CartService.instance.watchCart(widget.uid);

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update your cart. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CartItem>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _center(Icons.wifi_off, 'Could not load your cart', 'Please try again later.');
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange));
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return _center(Icons.shopping_cart_outlined, 'Your cart is empty',
              'Browse the Shop and tap + Cart on anything you like.');
        }
        final subtotal = items.fold<double>(0, (acc, i) => acc + i.lineTotal);
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, i) => _line(items[i]),
              ),
            ),
            _summary(items, subtotal),
          ],
        );
      },
    );
  }

  Widget _line(CartItem item) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(item.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => _thumbFallback())
                  : _thumbFallback(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 13, color: Colors.white, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('\$${item.price.toStringAsFixed(2)} each',
                      style: AppTheme.inter(size: 11, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _stepButton(Icons.remove,
                          item.quantity > 1
                              ? () => _run(() => CartService.instance.setQuantity(
                                  widget.uid, item.productId, item.quantity - 1))
                              : null),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('${item.quantity}',
                            style: AppTheme.orbitron(size: 12, weight: FontWeight.w700)),
                      ),
                      _stepButton(
                          Icons.add,
                          item.quantity < 99
                              ? () => _run(() => CartService.instance.setQuantity(
                                  widget.uid, item.productId, item.quantity + 1))
                              : null),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: 'Remove',
                  onPressed: () => _run(
                      () => CartService.instance.removeItem(widget.uid, item.productId)),
                ),
                Text('\$${item.lineTotal.toStringAsFixed(2)}',
                    style: AppTheme.orbitron(
                        size: 12, color: AppTheme.orange, weight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      );

  Widget _stepButton(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: onTap == null ? AppTheme.border : AppTheme.orange),
          ),
          child: Icon(icon, size: 14, color: onTap == null ? Colors.white24 : AppTheme.orange),
        ),
      );

  Widget _summary(List<CartItem> items, double subtotal) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: const BoxDecoration(
          color: AppTheme.card,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _totalRow('Subtotal', subtotal, bold: false),
              const SizedBox(height: 6),
              _totalRow('Total', subtotal, bold: true),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CheckoutScreen(items: items)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('CHECKOUT',
                      style: AppTheme.orbitron(
                          size: 11, color: Colors.black, weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _totalRow(String label, double value, {required bool bold}) => Row(
        children: [
          Expanded(
            child: Text(label,
                style: bold
                    ? AppTheme.orbitron(size: 12, weight: FontWeight.w700)
                    : AppTheme.inter(size: 12, color: Colors.grey)),
          ),
          Text('\$${value.toStringAsFixed(2)}',
              style: bold
                  ? AppTheme.orbitron(size: 14, color: AppTheme.orange, weight: FontWeight.w800)
                  : AppTheme.inter(size: 12, color: Colors.grey)),
        ],
      );

  Widget _thumbFallback() => Container(
        width: 60,
        height: 60,
        color: AppTheme.bg,
        alignment: Alignment.center,
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 24),
      );

  Widget _center(IconData icon, String title, String subtitle) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey, size: 36),
              const SizedBox(height: 10),
              Text(title,
                  style: AppTheme.orbitron(size: 12, color: Colors.grey, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(size: 11, color: Colors.grey)),
            ],
          ),
        ),
      );
}
