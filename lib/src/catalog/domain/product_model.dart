import 'package:cloud_firestore/cloud_firestore.dart';

class ProductVariant {
  final String size;
  final int stock;

  ProductVariant({required this.size, required this.stock});

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      size: map['size'] ?? '',
      stock: map['stock']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'size': size, 'stock': stock};
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final double ratingAverage;
  final List<ProductVariant> variants;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    required this.ratingAverage,
    required this.variants,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      ratingAverage: (map['ratingAverage'] ?? 0.0).toDouble(),
      variants:
          (map['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ¡NUEVO! Modelo para las reseñas
class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ReviewModel(
      id: documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Usuario',
      userPhotoUrl: map['userPhotoUrl'],
      rating: (map['rating'] ?? 5.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
