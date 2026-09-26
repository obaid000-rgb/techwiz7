import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import 'invoice_screen.dart';

String formatOrderDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '${months[d.month - 1]} ${d.day}, ${d.year} · $h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

Color orderStatusColor(String status) {
  switch (status) {
    case kOrderProcessing:
      return AppTheme.orange;
    case kOrderCompleted:
      return Colors.green;
    default:
      return AppTheme.cyan;
  }
}

class OrderStatusChip extends StatelessWidget {
  final String status;
  const OrderStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(status.toUpperCase(),
          style: AppTheme.orbitron(size: 8, color: color, weight: FontWeight.w700)),
    );
  }
}

/// Receipt / confirmation for one order, live-updating so status changes made
/// by an admin show up. Contents are the order's own snapshot, never the
/// current product data.
class OrderReceiptScreen extends StatefulWidget {
  final String orderId;
  final bool justPlaced;
  const OrderReceiptScreen({super.key, required this.orderId, this.justPlaced = false});

  @override
  State<OrderReceiptScreen> createState() => _OrderReceiptScreenState();
}

class _OrderReceiptScreenState extends State<OrderReceiptScreen> {
  late final Stream<OrderModel?> _stream =
      OrderService.instance.watchOrder(widget.orderId);

  void _backToShop() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(widget.justPlaced ? Icons.close : Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: widget.justPlaced ? _backToShop : () => Navigator.pop(context),
        ),
        title: Text(widget.justPlaced ? 'Order Confirmed' : 'Order Details',
            style: AppTheme.orbitron(size: 13)),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(Icons.wifi_off, 'Could not load this order');
          }
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange));
          }
          final order = snapshot.data;
          if (order == null) return _message(Icons.receipt_long, 'Order not found');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.justPlaced) ...[
                _placedBanner(order),
                const SizedBox(height: 16),
              ],
              OrderReceiptBody(order: order),
              const SizedBox(height: 14),
              _invoiceButton(order),
              if (widget.justPlaced) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _backToShop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('BACK TO SHOP',
                        style: AppTheme.orbitron(
                            size: 11, color: Colors.black, weight: FontWeight.w800)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _invoiceButton(OrderModel order) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            final user = AuthService.instance.currentUser;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoiceScreen(
                  order: order,
                  customerName: user?.name ?? '',
                  customerEmail: user?.email ?? '',
                ),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.accent),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.receipt_long_rounded, color: AppTheme.accent, size: 18),
          label: Text('VIEW INVOICE',
              style: AppTheme.orbitron(size: 10, color: AppTheme.accent, weight: FontWeight.w700)),
        ),
      );

  Widget _placedBanner(OrderModel order) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order placed!',
                      style: AppTheme.orbitron(size: 13, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Invoice ${order.invoiceNumber} was generated automatically.',
                      style: AppTheme.inter(size: 11, color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text('You can find it any time under Profile → Purchase History.',
                      style: AppTheme.inter(size: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _message(IconData icon, String text) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(text, style: AppTheme.inter(size: 12, color: Colors.grey)),
          ],
        ),
      );
}

/// Itemized receipt for an order. Shared by the fan receipt screen and the
/// admin order detail screen.
class OrderReceiptBody extends StatelessWidget {
  final OrderModel order;
  const OrderReceiptBody({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Order ${order.displayNumber}',
                    style: AppTheme.orbitron(size: 13, weight: FontWeight.w700)),
              ),
              OrderStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(formatOrderDate(order.createdAt),
              style: AppTheme.inter(size: 11, color: Colors.grey)),
          const Divider(color: AppTheme.border, height: 28),
          for (final item in order.items) _line(item),
          const Divider(color: AppTheme.border, height: 28),
          _totalRow('Subtotal', order.subtotal, bold: false),
          const SizedBox(height: 6),
          _totalRow('Total', order.total, bold: true),
          const SizedBox(height: 12),
          Text('Simulated order — no payment was taken and nothing will be shipped.',
              style: AppTheme.inter(size: 10, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _line(OrderLineItem item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(item.imageUrl,
                      width: 44,
                      height: 44,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(size: 12, color: Colors.white, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${item.quantity} × \$${item.price.toStringAsFixed(2)}',
                      style: AppTheme.inter(size: 11, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('\$${item.lineTotal.toStringAsFixed(2)}',
                style: AppTheme.inter(size: 12, color: Colors.white, weight: FontWeight.w600)),
          ],
        ),
      );

  Widget _thumbFallback() => Container(
        width: 44,
        height: 44,
        color: AppTheme.bg,
        alignment: Alignment.center,
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 20),
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
}
