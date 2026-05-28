import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../checkout/domain/order_model.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists ? doc.data() : null;
  }

  // ¡NUEVO! Actualizar Perfil Básico (Nombre y Foto)
  Future<void> updateBasicProfile(String name, String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Actualizamos en Firebase Auth
    await user.updateDisplayName(name);
    await user.updatePhotoURL(photoUrl);

    // Actualizamos en Firestore
    await _firestore.collection('users').doc(user.uid).update({
      'name': name,
      'photoUrl': photoUrl,
    });
  }

  Future<void> addAddress(Map<String, dynamic> newAddress) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'addresses': FieldValue.arrayUnion([newAddress]),
    });
  }

  Future<void> addPaymentCard(Map<String, dynamic> newCard) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'paymentMethods': FieldValue.arrayUnion([newCard]),
    });
  }

  Future<List<OrderModel>> getMyOrders() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado.');
    QuerySnapshot snapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .get();
    final orders = snapshot.docs
        .map(
          (doc) =>
              OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }
}
