import '../../catalog/domain/product_model.dart';

class CartItemModel {
  final ProductModel product;
  final String selectedSize;
  final int quantity;

  CartItemModel({
    required this.product,
    required this.selectedSize,
    required this.quantity,
  });

  // Método para copiar el objeto modificando solo los campos necesarios (útil en BLoC)
  CartItemModel copyWith({
    ProductModel? product,
    String? selectedSize,
    int? quantity,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      selectedSize: selectedSize ?? this.selectedSize,
      quantity: quantity ?? this.quantity,
    );
  }

  // Calcula el subtotal de este artículo específico
  double get subtotal => product.price * quantity;
}
