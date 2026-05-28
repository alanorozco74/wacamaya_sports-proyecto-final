import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/network_image.dart';
import '../../cart/presentation/cart_screen.dart';
import '../data/catalog_repository.dart';
import '../domain/product_model.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  final String? categoryFilter;
  final String? searchQuery; // ¡NUEVO! Soporte para barra de búsqueda

  const CatalogScreen({super.key, this.categoryFilter, this.searchQuery});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final CatalogRepository _catalogRepo = CatalogRepository();
  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    // Si viene de una categoría
    if (widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty) {
      _productsFuture = _catalogRepo.getProductsByCategory(
        widget.categoryFilter!,
      );
    }
    // Si viene de la barra de búsqueda
    else if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      // Obtenemos todos y filtramos localmente por nombre
      _productsFuture = _catalogRepo.getAllProducts().then((products) {
        return products
            .where(
              (p) => p.name.toLowerCase().contains(
                widget.searchQuery!.toLowerCase(),
              ),
            )
            .toList();
      });
    }
    // Si es el catálogo general
    else {
      _productsFuture = _catalogRepo.getAllProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Todos los Productos';
    if (widget.categoryFilter != null)
      title = 'Categoría: ${widget.categoryFilter!.toUpperCase()}';
    if (widget.searchQuery != null) title = 'Búsqueda: "${widget.searchQuery}"';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.activeBlue),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    widget.searchQuery != null
                        ? 'No encontramos "${widget.searchQuery}"'
                        : 'No se encontraron productos.',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio:
                  0.58, // Ajustado para el nuevo diseño de tarjeta
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(products[index]);
            },
          );
        },
      ),
    );
  }

  // Tarjeta rediseñada para coincidir con la del Home
  Widget _buildProductCard(ProductModel product) {
    final String imageToShow = product.images.isNotEmpty
        ? product.images.first
        : '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: imageToShow.isNotEmpty
                  ? CustomNetworkImage(
                      imageName: imageToShow,
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.image, color: Colors.grey, size: 50),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          Text(
                            product.ratingAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.activeBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailScreen(product: product),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Ver Detalles'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
