import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/product_model.dart';

class CatalogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<ProductModel>> getAllProducts() async {
    QuerySnapshot snapshot = await _firestore.collection('products').get();
    return snapshot.docs
        .map(
          (doc) =>
              ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    QuerySnapshot snapshot = await _firestore
        .collection('products')
        .where('category', isEqualTo: category.toLowerCase())
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // ¡NUEVO! Obtener reseñas de un producto
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

  // ¡NUEVO! Añadir reseña y actualizar el promedio del producto
  Future<void> addReview(
    String productId,
    double rating,
    String comment,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión para comentar.');

    // 1. Guardar la reseña en la sub-colección "reviews"
    final reviewRef = _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc();
    await reviewRef.set({
      'userId': user.uid,
      'userName': user.displayName ?? 'Usuario Deportivo',
      'userPhotoUrl': user.photoURL,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.now(),
    });

    // 2. Recalcular el promedio de estrellas general
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
        : rating;

    // 3. Actualizar el producto con su nueva calificación
    await _firestore.collection('products').doc(productId).update({
      'ratingAverage': newAverage,
    });
  }
}
