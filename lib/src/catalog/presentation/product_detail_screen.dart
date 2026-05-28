import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/network_image.dart';
import '../domain/product_model.dart';
import '../data/catalog_repository.dart';
import '../../cart/presentation/cubit/cart_cubit.dart';
import '../../cart/presentation/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CatalogRepository _catalogRepo = CatalogRepository();
  String? _selectedSize;

  // Renderizador de Estrellas visuales
  Widget _buildStars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (rating >= index + 1)
          return Icon(Icons.star, color: Colors.amber, size: size);
        if (rating >= index + 0.5)
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        return Icon(Icons.star_border, color: Colors.amber, size: size);
      }),
    );
  }

  void _showAddReviewDialog() {
    int localRating = 5;
    final commentCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Escribir Reseña',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('¿Qué calificación le das?'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      icon: Icon(
                        index < localRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () =>
                          setStateDialog(() => localRating = index + 1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Cuéntanos qué te pareció el producto...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        if (commentCtrl.text.trim().isEmpty) return;
                        setStateDialog(() => isSaving = true);
                        try {
                          await _catalogRepo.addReview(
                            widget.product.id,
                            localRating.toDouble(),
                            commentCtrl.text.trim(),
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            setState(
                              () {},
                            ); // Recarga la pantalla para mostrar la nueva reseña
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('¡Reseña publicada!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setStateDialog(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Publicar'),
                    ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageToShow = widget.product.images.isNotEmpty
        ? widget.product.images.first
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN
            Container(
              width: double.infinity,
              height: 350,
              color: AppColors.pureWhite,
              child: imageToShow.isNotEmpty
                  ? CustomNetworkImage(
                      imageName: imageToShow,
                      fit: BoxFit.contain,
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 100, color: Colors.grey),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO Y PRECIO
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${widget.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.activeBlue,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SELECTOR DE TALLAS
                  const Text(
                    'Selecciona tu talla',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: widget.product.variants.map((variant) {
                      final bool hasStock = variant.stock > 0;
                      final bool isSelected = _selectedSize == variant.size;

                      return GestureDetector(
                        onTap: hasStock
                            ? () => setState(() => _selectedSize = variant.size)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.activeBlue
                                : (hasStock
                                      ? AppColors.pureWhite
                                      : Colors.grey.shade300),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.activeBlue
                                  : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            variant.size,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.pureWhite
                                  : (hasStock ? Colors.black : Colors.grey),
                              fontWeight: FontWeight.bold,
                              decoration: hasStock
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // DESCRIPCIÓN
                  const Text(
                    'Descripción',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description.isNotEmpty
                        ? widget.product.description
                        : 'No hay descripción disponible.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),

                  const Divider(height: 48, thickness: 1),

                  // SECCIÓN DE RESEÑAS (En tiempo real)
                  FutureBuilder<List<ReviewModel>>(
                    future: _catalogRepo.getProductReviews(widget.product.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());

                      final reviews = snapshot.data ?? [];

                      // Calculamos el promedio en vivo
                      double avgRating = 0.0;
                      if (reviews.isNotEmpty) {
                        double sum = reviews.fold(
                          0,
                          (prev, r) => prev + r.rating,
                        );
                        avgRating = sum / reviews.length;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Valoración',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _showAddReviewDialog,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Escribir reseña'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // PROMEDIO ESTRELLAS
                          Row(
                            children: [
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStars(avgRating, size: 20),
                                  Text(
                                    '${reviews.length} reseñas',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // LISTA DE COMENTARIOS
                          if (reviews.isEmpty)
                            const Text(
                              'Sé el primero en calificar este producto.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: reviews.length,
                              itemBuilder: (context, index) {
                                final r = reviews[index];
                                final dateStr =
                                    '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Círculo con Foto del Usuario
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.grey.shade300,
                                        child: ClipOval(
                                          child: SizedBox(
                                            width: 40,
                                            height: 40,
                                            child:
                                                r.userPhotoUrl != null &&
                                                    r.userPhotoUrl!.isNotEmpty
                                                ? CustomNetworkImage(
                                                    imageName: r.userPhotoUrl!,
                                                  )
                                                : const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Contenido de la reseña
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  r.userName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  dateStr,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            _buildStars(r.rating, size: 14),
                                            const SizedBox(height: 8),
                                            Text(
                                              r.comment,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // BOTÓN INFERIOR AÑADIR AL CARRITO
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _selectedSize == null
              ? null
              : () {
                  context.read<CartCubit>().addToCart(
                    widget.product,
                    _selectedSize!,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '¡${widget.product.name} (Talla: $_selectedSize) agregado!',
                      ),
                      backgroundColor: Colors.green,
                      action: SnackBarAction(
                        label: 'VER CARRITO',
                        textColor: AppColors.pureWhite,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CartScreen(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: _selectedSize == null
                ? Colors.grey
                : AppColors.activeBlue,
          ),
          child: const Text(
            'Añadir al Carrito',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
