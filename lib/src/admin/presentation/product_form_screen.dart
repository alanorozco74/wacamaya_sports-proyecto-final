import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../catalog/domain/product_model.dart';
import '../data/admin_repository.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? productToEdit;
  const ProductFormScreen({super.key, this.productToEdit});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminRepo = AdminRepository();

  late TextEditingController _nameCtrl, _descCtrl, _priceCtrl, _imageCtrl;
  final TextEditingController _newSizeCtrl = TextEditingController();
  final TextEditingController _newStockCtrl = TextEditingController();

  String _selectedCategory = 'jerseys';
  final List<String> _categories = [
    'jerseys',
    'shorts',
    'tenis',
    'termos',
    'mochilas',
  ];
  List<ProductVariant> _variants = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _imageCtrl = TextEditingController(
      text: p?.images.isNotEmpty == true ? p!.images.join(',') : '',
    );

    if (p != null) {
      if (_categories.contains(p.category)) _selectedCategory = p.category;
      _variants = List.from(p.variants);
    }
  }

  void _addVariant() {
    final size = _newSizeCtrl.text.trim().toUpperCase();
    final stock = int.tryParse(_newStockCtrl.text.trim()) ?? 0;
    if (size.isNotEmpty && stock >= 0) {
      setState(() {
        final index = _variants.indexWhere((v) => v.size == size);
        if (index >= 0)
          _variants[index] = ProductVariant(
            size: size,
            stock: _variants[index].stock + stock,
          );
        else
          _variants.add(ProductVariant(size: size, stock: stock));
        _newSizeCtrl.clear();
        _newStockCtrl.clear();
      });
    }
  }

  // ¡NUEVO! Diálogo para editar el stock de una talla existente rápidamente
  void _editVariantStock(int index) {
    final editCtrl = TextEditingController(
      text: _variants[index].stock.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modificar Stock - Talla ${_variants[index].size}'),
        content: TextField(
          controller: editCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Piezas Reales'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              int newStock = int.tryParse(editCtrl.text) ?? 0;
              setState(
                () => _variants[index] = ProductVariant(
                  size: _variants[index].size,
                  stock: newStock,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate() || _variants.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      List<String> imagesList = _imageCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final product = ProductModel(
        id: widget.productToEdit?.id ?? '',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text) ?? 0.0,
        category: _selectedCategory,
        images: imagesList,
        ratingAverage: 5.0,
        variants: _variants,
      );
      widget.productToEdit == null
          ? await _adminRepo.createProduct(product)
          : await _adminRepo.updateProduct(product);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productToEdit != null ? 'Editar Producto' : 'Nuevo Producto',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Precio (\$)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? 'Req' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            border: OutlineInputBorder(),
                          ),
                          items: _categories
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Imagen (Nombre Github o URL)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gestión de Tallas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _newSizeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Talla',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _newStockCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Pz',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_box,
                                color: AppColors.activeBlue,
                                size: 40,
                              ),
                              onPressed: _addVariant,
                            ),
                          ],
                        ),
                        const Divider(),
                        ..._variants.asMap().entries.map(
                          (entry) => ListTile(
                            dense: true,
                            title: Text('Talla: ${entry.value.size}'),
                            subtitle: Text('Stock: ${entry.value.stock}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: AppColors.activeBlue,
                                    size: 20,
                                  ),
                                  onPressed: () => _editVariantStock(entry.key),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _variants.removeAt(entry.key),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveProduct,
                    child: const Text('Guardar Producto'),
                  ),
                ],
              ),
            ),
    );
  }
}
