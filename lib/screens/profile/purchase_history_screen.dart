import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../shop/order_receipt_screen.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  final String uid;
  const PurchaseHistoryScreen({super.key, required this.uid});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  late final Stream<List<OrderModel>> _stream =
      OrderService.instance.watchUserOrders(widget.uid);

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
        title: Text('Purchase History', style: AppTheme.orbitron(size: 13)),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _center(Icons.wifi_off, 'Could not load your orders', 'Please try again later.');
          }
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange));
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return _center(Icons.receipt_long_outlined, 'No orders yet',
                'Orders you place in the Shop will appear here.');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, i) => _row(orders[i]),
          );
        },
      ),
    );
  }

  Widget _row(OrderModel order) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderReceiptScreen(orderId: order.orderId)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long, color: AppTheme.orange, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ${order.displayNumber}',
                        style: AppTheme.inter(size: 13, color: Colors.white, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                        '${formatOrderDate(order.createdAt)}  •  ${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 10, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${order.total.toStringAsFixed(2)}',
                      style: AppTheme.orbitron(
                          size: 12, color: AppTheme.orange, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  OrderStatusChip(status: order.status),
                ],
              ),
            ],
          ),
        ),
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
