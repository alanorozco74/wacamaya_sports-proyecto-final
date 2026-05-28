import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String productName;
  final String size;
  final int quantity;
  final double price;
  final String image; // ¡NUEVO! Guardaremos la imagen para la vista previa

  OrderItem({
    required this.productId,
    required this.productName,
    required this.size,
    required this.quantity,
    required this.price,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'size': size,
      'quantity': quantity,
      'price': price,
      'image': image,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      size: map['size'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      price: (map['price'] ?? 0.0).toDouble(),
      image: map['image'] ?? '',
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double total;
  final String address;
  final String paymentMethod;
  final DateTime createdAt;
  final String status;
  final String? oxxoReference; // ¡NUEVO! Referencia de OXXO (opcional)

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.address,
    required this.paymentMethod,
    required this.createdAt,
    required this.status,
    this.oxxoReference,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'address': address,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'oxxoReference': oxxoReference,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderModel(
      id: documentId,
      userId: map['userId'] ?? '',
      items:
          (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: (map['total'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      oxxoReference: map['oxxoReference'],
    );
  }
}
