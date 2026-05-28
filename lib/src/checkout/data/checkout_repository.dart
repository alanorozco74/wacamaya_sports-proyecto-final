import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/order_model.dart';
import '../../catalog/domain/product_model.dart';

class CheckoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createOrder({
    required List<OrderItem> orderItems,
    required double total,
    required String address,
    required String paymentMethod,
    String? oxxoReference,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Debes iniciar sesión.');

    // Usamos runTransaction para asegurar que el descuento de stock sea exacto y en tiempo real
    await _firestore.runTransaction((transaction) async {
      // 1. Leer y preparar el nuevo stock para CADA producto antes de guardar nada
      for (var item in orderItems) {
        DocumentReference prodRef = _firestore
            .collection('products')
            .doc(item.productId);
        DocumentSnapshot prodSnap = await transaction.get(prodRef);

        if (prodSnap.exists) {
          ProductModel product = ProductModel.fromMap(
            prodSnap.data() as Map<String, dynamic>,
            prodSnap.id,
          );

          List<ProductVariant> updatedVariants = product.variants.map((
            variant,
          ) {
            if (variant.size == item.size) {
              int newStock = variant.stock - item.quantity;
              return ProductVariant(
                size: variant.size,
                stock: newStock < 0 ? 0 : newStock,
              );
            }
            return variant;
          }).toList();

          // Actualizamos el producto en la transacción
          transaction.update(prodRef, {
            'variants': updatedVariants.map((v) => v.toMap()).toList(),
          });
        }
      }

      // 2. Si todo el stock se descontó bien, creamos la orden
      final orderDoc = _firestore.collection('orders').doc();
      final newOrder = OrderModel(
        id: orderDoc.id,
        userId: currentUser.uid,
        items: orderItems,
        total: total,
        address: address,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        status: 'pending',
        oxxoReference: oxxoReference,
      );

      transaction.set(orderDoc, newOrder.toMap());
    });
  }
}
