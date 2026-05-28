import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/cart_item_model.dart';
import '../../../catalog/domain/product_model.dart';

// Estado del carrito: simplemente contiene la lista actual de productos
class CartState {
  final List<CartItemModel> items;

  CartState({required this.items});

  // Calcula el precio total de todo el carrito
  double get totalPrice => items.fold(0, (sum, item) => sum + item.subtotal);

  // Calcula el número total de piezas añadidas
  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.quantity);
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartState(items: []));

  // Agregar un producto al carrito
  void addToCart(ProductModel product, String size) {
    final currentItems = List<CartItemModel>.from(state.items);

    // Verificamos si ya existe el mismo producto con la misma talla
    final existingIndex = currentItems.indexWhere(
      (item) => item.product.id == product.id && item.selectedSize == size,
    );

    if (existingIndex >= 0) {
      // Si ya existe, incrementamos la cantidad en 1
      final existingItem = currentItems[existingIndex];
      currentItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
    } else {
      // Si es nuevo, lo añadimos a la lista con cantidad inicial de 1
      currentItems.add(
        CartItemModel(product: product, selectedSize: size, quantity: 1),
      );
    }

    emit(CartState(items: currentItems));
  }

  // Incrementar cantidad de un elemento
  void incrementQuantity(CartItemModel item) {
    final currentItems = List<CartItemModel>.from(state.items);
    final index = currentItems.indexOf(item);
    if (index >= 0) {
      currentItems[index] = item.copyWith(quantity: item.quantity + 1);
      emit(CartState(items: currentItems));
    }
  }

  // Decrementar cantidad de un elemento (si llega a 0, se elimina automáticamente)
  void decrementQuantity(CartItemModel item) {
    final currentItems = List<CartItemModel>.from(state.items);
    final index = currentItems.indexOf(item);
    if (index >= 0) {
      if (item.quantity > 1) {
        currentItems[index] = item.copyWith(quantity: item.quantity - 1);
      } else {
        currentItems.removeAt(index);
      }
      emit(CartState(items: currentItems));
    }
  }

  // Eliminar por completo un artículo del carrito
  void removeFromCart(CartItemModel item) {
    final currentItems = List<CartItemModel>.from(state.items);
    currentItems.remove(item);
    emit(CartState(items: currentItems));
  }

  // Vaciar carrito (útil al finalizar la compra)
  void clearCart() {
    emit(CartState(items: []));
  }
}
