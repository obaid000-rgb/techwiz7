import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import 'cart_service.dart';
import 'firestore_db.dart';

class OrderService {
  static final OrderService instance = OrderService._();
  OrderService._();

  CollectionReference<Map<String, dynamic>> get _orders =>
      FirestoreDb.instance.collection('orders');

  /// Creates the order from the cart lines exactly as shown at checkout, and
  /// empties the cart in the same atomic batch. Returns the new order id.
  Future<String> placeOrder(String uid, List<CartItem> cart) async {
    if (cart.isEmpty) throw StateError('Cart is empty');
    final items = cart
        .map((c) => OrderLineItem(
              name: c.name,
              price: c.price,
              imageUrl: c.imageUrl,
              quantity: c.quantity,
            ))
        .toList();
    final subtotal = items.fold<double>(0, (acc, i) => acc + i.lineTotal);
    final ref = _orders.doc();
    final batch = FirestoreDb.instance.batch();
    batch.set(ref, {
      'orderId': ref.id,
      'userId': uid,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'total': subtotal,
      'status': kOrderPlaced,
      'createdAt': FieldValue.serverTimestamp(),
    });
    for (final c in cart) {
      batch.delete(CartService.instance.itemRef(uid, c.productId));
    }
    await batch.commit();
    return ref.id;
  }

  Stream<OrderModel?> watchOrder(String orderId) => _orders
      .doc(orderId)
      .snapshots()
      .map((d) => d.exists ? OrderModel.fromMap(d.data()!, d.id) : null);

  /// The signed-in user's own orders, newest first. Filtered by userId (the
  /// rules only allow reading your own orders) and sorted on-device, which
  /// avoids needing a composite index.
  Stream<List<OrderModel>> watchUserOrders(String uid) => _orders
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  /// Admin only: every order across all users, newest first.
  Stream<List<OrderModel>> watchAllOrders() => _orders
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList());

  Future<void> updateStatus(String orderId, String status) =>
      _orders.doc(orderId).update({'status': status});
}
