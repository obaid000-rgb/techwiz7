import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import 'order_receipt_screen.dart';

/// Simulated checkout: a read-only bill summary and "Place Order". There is
/// deliberately no address, payment or delivery step.
class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  const CheckoutScreen({super.key, required this.items});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _placing = false;

  double get _subtotal =>
      widget.items.fold<double>(0, (acc, i) => acc + i.lineTotal);

  Future<void> _placeOrder() async {
    final user = AuthService.instance.currentUser;
    if (user == null || widget.items.isEmpty) return;
    setState(() => _placing = true);
    try {
      final orderId =
          await OrderService.instance.placeOrder(user.uid, widget.items);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderReceiptScreen(orderId: orderId, justPlaced: true),
        ),
        (route) => route.isFirst,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not place your order. Please try again.')),
      );
    }
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
          onPressed: _placing ? null : () => Navigator.pop(context),
        ),
        title: Text('Checkout', style: AppTheme.orbitron(size: 13)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('ORDER SUMMARY',
              style: AppTheme.orbitron(size: 10, color: Colors.grey, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                for (final item in widget.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.inter(
                                      size: 12, color: Colors.white, weight: FontWeight.w600)),
                              Text('${item.quantity} × \$${item.price.toStringAsFixed(2)}',
                                  style: AppTheme.inter(size: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('\$${item.lineTotal.toStringAsFixed(2)}',
                            style: AppTheme.inter(
                                size: 12, color: Colors.white, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const Divider(color: AppTheme.border, height: 20),
                _totalRow('Subtotal', _subtotal, bold: false),
                const SizedBox(height: 6),
                _totalRow('Total', _subtotal, bold: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('This is a simulated checkout — no payment is taken and nothing is shipped.',
              style: AppTheme.inter(size: 11, color: Colors.white38)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placing || widget.items.isEmpty ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _placing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text('PLACE ORDER',
                      style: AppTheme.orbitron(
                          size: 11, color: Colors.black, weight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

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
}
