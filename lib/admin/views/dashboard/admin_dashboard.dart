import 'package:flutter/material.dart';
import '../../../models/order_model.dart';
import '../../../screens/shop/order_receipt_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/category_service.dart';
import '../../../services/event_service.dart';
import '../../../services/merchandise_service.dart';
import '../../../services/order_service.dart';
import '../../../services/post_service.dart';
import '../../../services/user_service.dart';
import '../../../theme/app_theme.dart';
import 'admin_shell.dart';
import '../events/event_form_screen.dart';
import '../merchandise/merchandise_form_screen.dart';
import '../orders/order_management_screen.dart';
import '../content/post_form_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // All live Firestore streams, created once. Orders feed the pending alert,
  // revenue and recent-orders panels, so a newly placed order shows up
  // without a refresh.
  late final Stream<List<OrderModel>> _orders = OrderService.instance.watchAllOrders();
  late final Stream<List<UserData>> _users = UserService.instance.watchUsers();
  late final Stream<int> _userCount =
      UserService.instance.watchUsers().map((l) => l.length);
  late final Stream<int> _orderCount =
      OrderService.instance.watchAllOrders().map((l) => l.length);
  late final Stream<int> _postCount = PostService.instance.watchPosts().map((l) => l.length);
  late final Stream<int> _merchCount =
      MerchandiseService.instance.watchMerchandise().map((l) => l.length);
  late final Stream<int> _eventCount = EventService.instance.watchEvents().map((l) => l.length);
  late final Stream<int> _categoryCount =
      CategoryService.instance.watchCategories().map((l) => l.length);

  void _open(String section) => AdminShell.openSection(context, section);

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserData>>(
      stream: _users,
      builder: (context, userSnap) => StreamBuilder<List<OrderModel>>(
        stream: _orders,
        builder: (context, orderSnap) {
          final users = userSnap.data ?? const <UserData>[];
          final usersById = {for (final u in users) u.uid: u};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dashboard_outlined, color: AppTheme.accent, size: 18),
                    const SizedBox(width: 8),
                    Text('Overview', style: AppTheme.orbitron(size: 14, weight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Live data from Firestore · tap any card to manage it',
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
                const SizedBox(height: 16),
                _PendingOrdersAlert(snap: orderSnap, onTap: () => _open('Orders')),
                const SizedBox(height: 16),
                _sectionLabel('QUICK ACTIONS'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickAction(
                      label: 'Add Product',
                      icon: Icons.shopping_bag_outlined,
                      color: AppTheme.orange,
                      onTap: () => _push(const MerchandiseFormScreen()),
                    ),
                    _QuickAction(
                      label: 'Add Event',
                      icon: Icons.event_outlined,
                      color: AppTheme.pink,
                      onTap: () => _push(const EventFormScreen()),
                    ),
                    _QuickAction(
                      label: 'Add Content',
                      icon: Icons.article_outlined,
                      color: AppTheme.cyan,
                      onTap: () => _push(const PostFormScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _RevenueCard(snap: orderSnap),
                const SizedBox(height: 20),
                _sectionLabel('COUNTS'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _CountCard(
                      label: 'Users',
                      icon: Icons.people_outline,
                      color: AppTheme.accent,
                      stream: _userCount,
                      onTap: () => _open('Users'),
                    ),
                    _CountCard(
                      label: 'Orders',
                      icon: Icons.receipt_long_outlined,
                      color: AppTheme.orange,
                      stream: _orderCount,
                      onTap: () => _open('Orders'),
                    ),
                    _CountCard(
                      label: 'Posts',
                      icon: Icons.article_outlined,
                      color: AppTheme.cyan,
                      stream: _postCount,
                      onTap: () => _open('Content'),
                    ),
                    // Merchandise is the MERCH tab inside the Content section.
                    _CountCard(
                      label: 'Merchandise',
                      icon: Icons.shopping_bag_outlined,
                      color: AppTheme.orange,
                      stream: _merchCount,
                      onTap: () => _open('Content'),
                    ),
                    _CountCard(
                      label: 'Events',
                      icon: Icons.event_outlined,
                      color: AppTheme.pink,
                      stream: _eventCount,
                      onTap: () => _open('Events'),
                    ),
                    _CountCard(
                      label: 'Categories',
                      icon: Icons.category_outlined,
                      color: AppTheme.orange,
                      stream: _categoryCount,
                      onTap: () => _open('Categories'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _sectionLabel('RECENT ORDERS')),
                    TextButton(
                      onPressed: () => _open('Orders'),
                      child: Text('View all',
                          style: AppTheme.inter(size: 11, color: AppTheme.orange)),
                    ),
                  ],
                ),
                _RecentOrders(
                  snap: orderSnap,
                  usersById: usersById,
                  onOpen: (order, customer) => _push(AdminOrderDetailScreen(
                    orderId: order.orderId,
                    customer: customer,
                    customerName: usersById[order.userId]?.name ?? '',
                    customerEmail: usersById[order.userId]?.email ?? '',
                  )),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: AppTheme.orbitron(size: 10, color: Colors.grey, letterSpacing: 0.8));
}

// ── Shared card shell (same look as the original count cards) ─────────────────

BoxDecoration _cardDecoration(Color color) => BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    );

Widget _loadingLine(Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      ),
    );

Widget _errorLine(String text) => Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTheme.inter(size: 11, color: Colors.redAccent))),
      ],
    );

class _CountCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Stream<int> stream;
  final VoidCallback onTap;

  const _CountCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.stream,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(color),
            child: StreamBuilder<int>(
              stream: stream,
              builder: (context, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: color),
                      )
                    else if (snapshot.hasError)
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 18)
                    else
                      Text('${snapshot.data ?? 0}',
                          style: AppTheme.orbitron(
                              size: 28, color: Colors.white, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(label, style: AppTheme.inter(size: 11, color: Colors.grey)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingOrdersAlert extends StatelessWidget {
  final AsyncSnapshot<List<OrderModel>> snap;
  final VoidCallback onTap;
  const _PendingOrdersAlert({required this.snap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (snap.hasError) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(Colors.redAccent),
        child: _errorLine('Could not load orders'),
      );
    }
    if (!snap.hasData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(AppTheme.orange),
        child: _loadingLine(AppTheme.orange),
      );
    }
    final pending = snap.data!.where((o) => o.status == kOrderPlaced).length;
    final hasPending = pending > 0;
    final color = hasPending ? AppTheme.pink : Colors.green;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: hasPending ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: hasPending ? 0.7 : 0.4)),
          ),
          child: Row(
            children: [
              Icon(hasPending ? Icons.pending_actions : Icons.check_circle_outline,
                  color: color, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPending
                          ? '$pending order${pending == 1 ? '' : 's'} awaiting action'
                          : 'All caught up',
                      style: AppTheme.orbitron(size: 12, color: Colors.white, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPending
                          ? 'Status "Placed" — tap to review in Orders'
                          : 'No orders are waiting in "Placed" status',
                      style: AppTheme.inter(size: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (hasPending) Icon(Icons.chevron_right, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(Icons.add, size: 16, color: color),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.inter(size: 12, color: color, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final AsyncSnapshot<List<OrderModel>> snap;
  const _RevenueCard({required this.snap});

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (snap.hasError) {
      content = _errorLine('Could not load revenue');
    } else if (!snap.hasData) {
      content = _loadingLine(Colors.green);
    } else {
      // Client-side sum over all fetched orders (fine at demo scale).
      final orders = snap.data!;
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final total = orders.fold<double>(0, (acc, o) => acc + o.total);
      final week = orders
          .where((o) => o.createdAt.isAfter(weekAgo))
          .fold<double>(0, (acc, o) => acc + o.total);
      content = Row(
        children: [
          Expanded(child: _figure('Total revenue', total, '${orders.length} orders')),
          Container(width: 1, height: 44, color: AppTheme.border),
          const SizedBox(width: 16),
          Expanded(child: _figure('Last 7 days', week, 'since ${_short(weekAgo)}')),
        ],
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(Colors.green),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payments_outlined, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Revenue (simulated)',
                  style: AppTheme.inter(size: 12, color: Colors.white, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _figure(String label, double value, String caption) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.inter(size: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('\$${value.toStringAsFixed(2)}',
                style: AppTheme.orbitron(size: 20, color: Colors.white, weight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Text(caption, style: AppTheme.inter(size: 10, color: Colors.white38)),
        ],
      );

  String _short(DateTime d) => '${d.day}/${d.month}';
}

class _RecentOrders extends StatelessWidget {
  final AsyncSnapshot<List<OrderModel>> snap;
  final Map<String, UserData> usersById;
  final void Function(OrderModel order, String customer) onOpen;
  const _RecentOrders({required this.snap, required this.usersById, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (snap.hasError) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(Colors.redAccent),
        child: _errorLine('Could not load recent orders'),
      );
    }
    if (!snap.hasData) return _loadingLine(AppTheme.orange);
    final recent = snap.data!.take(5).toList();
    if (recent.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: _cardDecoration(AppTheme.border),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, color: Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text('No orders yet', style: AppTheme.inter(size: 12, color: Colors.grey)),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final o in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _row(o, orderCustomerLabel(usersById[o.userId])),
          ),
      ],
    );
  }

  Widget _row(OrderModel o, String customer) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onOpen(o, customer),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${o.displayNumber}  •  \$${o.total.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 13, weight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 10, color: Colors.grey)),
                      Text(formatOrderDate(o.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OrderStatusChip(status: o.status),
              ],
            ),
          ),
        ),
      );
}
