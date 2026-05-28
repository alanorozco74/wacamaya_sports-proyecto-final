import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/network_image.dart';
import '../../catalog/domain/product_model.dart';
import '../data/admin_repository.dart';
import 'product_form_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final AdminRepository _adminRepo = AdminRepository();
  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = _adminRepo.getAllProducts();
    });
  }

  void _deleteProduct(String productId) async {
    await _adminRepo.deleteProduct(productId);
    _refreshProducts();
  }

  // ¡NUEVO! Diálogo para Moderar Reseñas
  void _manageReviews(ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reseñas: ${product.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: FutureBuilder<List<ReviewModel>>(
                  future: _adminRepo.getProductReviews(product.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.isEmpty)
                      return const Center(
                        child: Text('Este producto aún no tiene reseñas.'),
                      );

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final r = snapshot.data![index];
                        return Card(
                          color: AppColors.background,
                          elevation: 0,
                          child: ListTile(
                            leading: const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            title: Text('${r.rating} - ${r.userName}'),
                            subtitle: Text(r.comment),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _adminRepo.deleteReview(product.id, r.id);
                                Navigator.pop(context); // Cierra para refrescar
                                _refreshProducts();
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToForm([ProductModel? product]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(productToEdit: product),
      ),
    );
    if (result == true) _refreshProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const Center(
              child: Text('No hay productos en el inventario.'),
            );

          final products = snapshot.data!;

          return ListView.builder(
            itemCount: products.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final product = products[index];
              final imageToShow = product.images.isNotEmpty
                  ? product.images.first
                  : '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: imageToShow.isNotEmpty
                        ? CustomNetworkImage(imageName: imageToShow)
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                  subtitle: Text(
                    '\$${product.price} - ${product.category.toUpperCase()}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.comment, color: Colors.orange),
                        onPressed: () =>
                            _manageReviews(product), // Gestor de reseñas
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppColors.activeBlue,
                        ),
                        onPressed: () => _navigateToForm(product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(product.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.activeBlue,
        child: const Icon(Icons.add, color: AppColors.pureWhite),
        onPressed: () => _navigateToForm(),
      ),
    );
  }
}
