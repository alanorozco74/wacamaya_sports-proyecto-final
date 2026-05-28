import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/network_image.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/catalog_repository.dart';
import '../domain/product_model.dart';
import 'catalog_screen.dart';
import 'product_detail_screen.dart';
import '../../cart/presentation/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CatalogRepository _catalogRepo = CatalogRepository();
  late Future<List<ProductModel>> _allProductsFuture;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargamos los productos una sola vez para usarlos en el Carrusel y en la Grilla
    _allProductsFuture = _catalogRepo.getAllProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _navigateToCatalog(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatalogScreen(categoryFilter: category),
      ),
    );
  }

  void _performSearch() {
    final query = _searchCtrl.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CatalogScreen(searchQuery: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wacamaya Sports'),
        leading: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          ),
        ),
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
        future: _allProductsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.activeBlue),
            );
          }

          final List<ProductModel> products = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. BARRA DE BÚSQUEDA FUNCIONAL
                Container(
                  color: AppColors.primaryBlue,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) =>
                          _performSearch(), // Ejecuta la búsqueda al presionar "Enter" en el teclado
                      decoration: InputDecoration(
                        hintText: 'Buscar tenis, jerseys, mochilas...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward,
                            color: AppColors.activeBlue,
                          ),
                          onPressed: _performSearch,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. CARRUSEL DE IMÁGENES PROMOCIONALES (Dinámico)
                const SizedBox(height: 16),
                _buildCarousel(products),

                // 3. CATEGORÍAS
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _buildCategoryItem(
                        Icons.sports_soccer,
                        'Jerseys',
                        'jerseys',
                      ),
                      _buildCategoryItem(
                        Icons.dry_cleaning,
                        'Shorts',
                        'shorts',
                      ),
                      _buildCategoryItem(
                        Icons.directions_run,
                        'Tenis',
                        'tenis',
                      ),
                      _buildCategoryItem(Icons.local_drink, 'Termos', 'termos'),
                      _buildCategoryItem(
                        Icons.backpack,
                        'Mochilas',
                        'mochilas',
                      ),
                    ],
                  ),
                ),

                // 4. LO MÁS VENDIDO (Tarjetas Mejoradas)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Lo más vendido',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),

                if (products.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No hay productos disponibles por ahora.'),
                    ),
                  )
                else
                  GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio:
                              0.58, // Proporción ajustada para evitar desbordes
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: products.length > 4
                        ? 4
                        : products.length, // Mostramos un máximo de 4
                    itemBuilder: (context, index) {
                      return _buildProductCard(products[index]);
                    },
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // CARRUSEL VISUAL
  Widget _buildCarousel(List<ProductModel> products) {
    // Extraemos imágenes de los productos que tengamos (máximo 5)
    final List<String> carouselImages = products
        .expand((p) => p.images)
        .take(5)
        .toList();

    if (carouselImages.isEmpty)
      return const SizedBox(); // Si no hay fotos, no muestra nada

    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: PageController(
          viewportFraction: 0.9,
        ), // Deja ver un pedacito de la siguiente imagen
        itemCount: carouselImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // Usamos BoxFit.contain sobre un fondo blanco para que la ropa no se mutile
              child: CustomNetworkImage(
                imageName: carouselImages[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String title, String filterKey) {
    return GestureDetector(
      onTap: () => _navigateToCatalog(filterKey),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.pureWhite,
              child: Icon(icon, color: AppColors.activeBlue, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // NUEVA TARJETA DE PRODUCTO
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
          // IMAGEN (Contenida sin deformarse)
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(
                  alpha: 0.5,
                ), // Fondo gris muy claro para contrastar la foto
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
          // DETALLES E INFORMACIÓN
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
                  // Categoría y Estrellas
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
                  // Título
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Precio
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.activeBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  // Botón
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      },
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
