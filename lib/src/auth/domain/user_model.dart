import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final List<dynamic> addresses;
  final List<dynamic> paymentMethods;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.addresses = const [],
    this.paymentMethods = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'client',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      addresses: map['addresses'] ?? [],
      paymentMethods: map['paymentMethods'] ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'addresses': addresses,
      'paymentMethods': paymentMethods,
    };
  }
}
