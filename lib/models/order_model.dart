import 'package:cloud_firestore/cloud_firestore.dart';

const String kOrderPlaced = 'Placed';
const String kOrderProcessing = 'Processing';
const String kOrderCompleted = 'Completed';
const List<String> kOrderStatuses = [kOrderPlaced, kOrderProcessing, kOrderCompleted];

/// A purchased line, snapshotted at checkout — never a live product reference.
class OrderLineItem {
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;

  const OrderLineItem({
    required this.name,
    required this.price,
    this.imageUrl = '',
    required this.quantity,
  });

  double get lineTotal => price * quantity;

  factory OrderLineItem.fromMap(Map map) => OrderLineItem(
        name: map['name'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        imageUrl: map['imageUrl'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'quantity': quantity,
      };
}

/// orders/{orderId}. Simulated purchase record: no payment/delivery data.
class OrderModel {
  final String orderId;
  final String userId;
  final List<OrderLineItem> items;
  final double subtotal;
  final double total;
  final String status;
  final DateTime createdAt;

  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.total,
    this.status = kOrderPlaced,
    required this.createdAt,
  });

  int get itemCount => items.fold(0, (acc, i) => acc + i.quantity);

  /// Short human-readable order number.
  String get displayNumber =>
      '#${orderId.length > 8 ? orderId.substring(0, 8) : orderId}'.toUpperCase();

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) => OrderModel(
        orderId: docId,
        userId: map['userId'] as String? ?? '',
        items: (map['items'] as List? ?? [])
            .map((e) => OrderLineItem.fromMap(e as Map))
            .toList(),
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        total: (map['total'] as num?)?.toDouble() ?? 0,
        status: kOrderStatuses.contains(map['status'])
            ? map['status'] as String
            : kOrderPlaced,
        // Null briefly for a just-placed order until the server timestamp lands.
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
