import 'package:flutter/material.dart';
import '../../../models/order_model.dart';
import '../../../screens/shop/invoice_screen.dart';
import '../../../screens/shop/order_receipt_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/order_service.dart';
import '../../../services/user_service.dart';
import '../../../theme/app_theme.dart';

/// "Name (email)" for an order's customer, or a fallback if unknown.
String orderCustomerLabel(UserData? u) {
  if (u == null) return 'Unknown user';
  return u.name.isEmpty ? u.email : '${u.name} (${u.email})';
}

/// Admin: every order across all users, newest first. Customer name/email
/// come from the users collection (admins can read it); orders store only
/// the userId.
class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  late final Stream<List<OrderModel>> _orders = OrderService.instance.watchAllOrders();
  late final Stream<List<UserData>> _users = UserService.instance.watchUsers();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserData>>(
      stream: _users,
      builder: (context, userSnap) {
        final usersById = {for (final u in userSnap.data ?? <UserData>[]) u.uid: u};
        return StreamBuilder<List<OrderModel>>(
          stream: _orders,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.orange));
            }
            if (snapshot.hasError) {
              debugPrint('Orders load error: ${snapshot.error}');
              return Center(
                  child: Text('Could not load orders. Check your connection and try again.',
                      style: AppTheme.inter(color: Colors.redAccent)));
            }
            final orders = snapshot.data ?? [];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text('Orders', style: AppTheme.orbitron(size: 13)),
                      const SizedBox(width: 8),
                      Text('(${orders.length})',
                          style: AppTheme.inter(size: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Expanded(
                  child: orders.isEmpty
                      ? _empty()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: orders.length,
                          separatorBuilder: (context, i) => const SizedBox(height: 8),
                          itemBuilder: (context, i) =>
                              _row(context, orders[i], usersById[orders[i].userId]),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _row(BuildContext context, OrderModel order, UserData? user) {
    final customer = orderCustomerLabel(user);
    return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminOrderDetailScreen(
              orderId: order.orderId,
              customer: customer,
              customerName: user?.name ?? '',
              customerEmail: user?.email ?? '',
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
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
                    Text('${order.displayNumber}  •  \$${order.total.toStringAsFixed(2)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 13, weight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(customer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 10, color: Colors.grey)),
                    Text(
                        '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}  •  ${formatOrderDate(order.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 10, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OrderStatusChip(status: order.status),
            ],
          ),
        ),
      );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, color: Colors.grey, size: 36),
            const SizedBox(height: 12),
            Text('No orders yet', style: AppTheme.inter(size: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Orders placed by fans will appear here.',
                style: AppTheme.inter(size: 11, color: Colors.grey)),
          ],
        ),
      );
}

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;
  final String customer;
  final String customerName;
  final String customerEmail;
  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.customer,
    this.customerName = '',
    this.customerEmail = '',
  });

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  late final Stream<OrderModel?> _stream = OrderService.instance.watchOrder(widget.orderId);
  bool _saving = false;

  Future<void> _setStatus(String status) async {
    setState(() => _saving = true);
    try {
      await OrderService.instance.updateStatus(widget.orderId, status);
    } catch (e) {
      debugPrint('Order status update failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not update the order status. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Order Details', style: AppTheme.orbitron(size: 13)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.orange.withValues(alpha: 0.3)),
        ),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Orders load error: ${snapshot.error}');
            return Center(
                child: Text('Could not load this order. Check your connection and try again.',
                    style: AppTheme.inter(color: Colors.redAccent)));
          }
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.orange));
          }
          final order = snapshot.data;
          if (order == null) {
            return Center(
                child: Text('Order not found',
                    style: AppTheme.inter(size: 12, color: Colors.grey)));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Customer', style: AppTheme.inter(size: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(widget.customer, style: AppTheme.inter(size: 13, color: Colors.white)),
              const SizedBox(height: 16),
              Text('Status', style: AppTheme.inter(size: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: kOrderStatuses.map((s) {
                  final selected = order.status == s;
                  final color = orderStatusColor(s);
                  return Expanded(
                    child: GestureDetector(
                      onTap: _saving || selected ? null : () => _setStatus(s),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? color.withValues(alpha: 0.15) : AppTheme.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? color : AppTheme.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          s.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppTheme.orbitron(
                              size: 9,
                              color: selected ? color : Colors.grey,
                              weight: FontWeight.w700),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_saving) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2, color: AppTheme.orange),
              ],
              const SizedBox(height: 20),
              OrderReceiptBody(order: order),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvoiceScreen(
                      order: order,
                      customerName: widget.customerName.isEmpty ? widget.customer : widget.customerName,
                      customerEmail: widget.customerEmail,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.accent),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.receipt_long_rounded, color: AppTheme.accent, size: 18),
                label: Text('VIEW INVOICE',
                    style: AppTheme.orbitron(size: 10, color: AppTheme.accent, weight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }
}
