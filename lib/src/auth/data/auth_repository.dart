import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Importado para usar debugPrint
import '../domain/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registro de usuario
  Future<UserModel?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = credential.user;

      if (firebaseUser != null) {
        UserModel newUser = UserModel(
          uid: firebaseUser.uid,
          name: name,
          email: email,
          role: 'client',
          createdAt: DateTime.now(),
        );

        // Guardar en Firestore colección 'users'
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toMap());

        return newUser;
      }
    } catch (e) {
      // Lanzamos el error procesado por nuestro manejador detallado
      throw Exception(_handleAuthException(e));
    }
    return null;
  }

  // Inicio de sesión
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = credential.user;

      if (firebaseUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
    } catch (e) {
      throw Exception(_handleAuthException(e));
    }
    return null;
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Manejo de errores MEJORADO y DETALLADO
  String _handleAuthException(dynamic e) {
    // Imprime el error crudo e idéntico en la terminal de VS Code / CMD
    debugPrint('======================================================');
    debugPrint('=== DETECTADO ERROR EN BASE DE DATOS / AUTH ===');
    debugPrint(e.toString());
    debugPrint('======================================================');

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No se encontró un usuario con ese correo.';
        case 'wrong-password':
          return 'Contraseña incorrecta.';
        case 'email-already-in-use':
          return 'El correo ya está registrado.';
        case 'weak-password':
          return 'La contraseña es demasiado débil (mínimo 6 caracteres).';
        default:
          return 'Error de autenticación: ${e.message}';
      }
    }

    // Si el error no es de Auth, viene directamente de Firestore
    // Retornamos el mensaje original de Firebase para saber exactamente qué pasa
    return 'Error en Firestore: ${e.toString()}';
  }
}
