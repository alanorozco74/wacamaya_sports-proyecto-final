import 'package:cloud_firestore/cloud_firestore.dart';
import '../../catalog/domain/product_model.dart';
import '../../checkout/domain/order_model.dart';
import '../../auth/domain/user_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===================== CRUD PRODUCTOS =====================
  Future<List<ProductModel>> getAllProducts() async {
    QuerySnapshot snapshot = await _firestore.collection('products').get();
    return snapshot.docs
        .map(
          (doc) =>
              ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<void> createProduct(ProductModel product) async {
    final docRef = _firestore.collection('products').doc();
    await docRef.set({
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'category': product.category,
      'images': product.images,
      'ratingAverage': product.ratingAverage,
      'variants': product.variants.map((v) => v.toMap()).toList(),
    });
  }

  Future<void> updateProduct(ProductModel product) async {
    await _firestore.collection('products').doc(product.id).update({
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'category': product.category,
      'images': product.images,
      'variants': product.variants.map((v) => v.toMap()).toList(),
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  // ===================== GESTIÓN DE RESEÑAS =====================
  Future<List<ReviewModel>> getProductReviews(String productId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<void> deleteReview(String productId, String reviewId) async {
    await _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(reviewId)
        .delete();

    // Recalcular promedio
    final reviewsSnap = await _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .get();
    double totalStars = 0;
    for (var doc in reviewsSnap.docs) {
      totalStars += (doc.data()['rating'] ?? 0).toDouble();
    }
    double newAverage = reviewsSnap.docs.isNotEmpty
        ? (totalStars / reviewsSnap.docs.length)
        : 5.0;
    await _firestore.collection('products').doc(productId).update({
      'ratingAverage': newAverage,
    });
  }

  // ===================== GESTIÓN DE PEDIDOS =====================
  Future<List<OrderModel>> getAllOrders() async {
    QuerySnapshot snapshot = await _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  Future<void> deleteOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).delete();
  }

  // ===================== GESTIÓN DE USUARIOS =====================
  Future<List<UserModel>> getAllUsers() async {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _firestore.collection('users').doc(userId).update({'role': newRole});
  }

  Future<void> deleteUserDoc(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }
}
