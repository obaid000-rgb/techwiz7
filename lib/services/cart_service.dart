import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/merchandise.dart';
import 'firestore_db.dart';

class CartService {
  static final CartService instance = CartService._();
  CartService._();

  CollectionReference<Map<String, dynamic>> _cart(String uid) =>
      FirestoreDb.instance.collection('users').doc(uid).collection('cart');

  Stream<List<CartItem>> watchCart(String uid) => _cart(uid)
      .snapshots()
      .map((s) => s.docs.map((d) => CartItem.fromMap(d.data(), d.id)).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  /// Adds [quantity] of [product]; if it's already in the cart the quantity
  /// is increased and its name/price/image refreshed to the current values.
  Future<void> addToCart(String uid, Merchandise product, {int quantity = 1}) =>
      _cart(uid).doc(product.id).set({
        'productId': product.id,
        'name': product.name,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'quantity': FieldValue.increment(quantity),
      }, SetOptions(merge: true));

  /// Sets an exact quantity; 0 or less removes the line.
  Future<void> setQuantity(String uid, String productId, int quantity) =>
      quantity <= 0
          ? removeItem(uid, productId)
          : _cart(uid).doc(productId).update({'quantity': quantity});

  Future<void> removeItem(String uid, String productId) =>
      _cart(uid).doc(productId).delete();

  DocumentReference<Map<String, dynamic>> itemRef(String uid, String productId) =>
      _cart(uid).doc(productId);
}
