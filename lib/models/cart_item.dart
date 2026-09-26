/// One line in a user's cart (users/{uid}/cart/{productId}). Name, price and
/// image are copied from the product when it's added, and are what the
/// order snapshots at checkout.
class CartItem {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl = '',
    required this.quantity,
  });

  double get lineTotal => price * quantity;

  factory CartItem.fromMap(Map<String, dynamic> map, String docId) => CartItem(
        productId: map['productId'] as String? ?? docId,
        name: map['name'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        imageUrl: map['imageUrl'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'quantity': quantity,
      };
}
