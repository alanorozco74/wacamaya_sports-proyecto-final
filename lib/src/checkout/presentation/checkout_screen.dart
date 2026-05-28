import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../cart/presentation/cubit/cart_cubit.dart';
import '../data/checkout_repository.dart';
import '../domain/order_model.dart';
import '../../profile/data/profile_repository.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _checkoutRepo = CheckoutRepository();
  final _profileRepo = ProfileRepository();

  bool _isLoadingData = true;
  bool _isProcessing = false;

  List<dynamic> _savedAddresses = [];
  List<dynamic> _savedCards = [];

  Map<String, dynamic>? _selectedAddress;
  String _selectedPaymentType = 'card'; // 'card', 'oxxo', 'paypal'
  Map<String, dynamic>? _selectedCard;

  // Formularios nueva dirección
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();

  // Formularios nueva tarjeta
  final _cardHolderCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final data = await _profileRepo.getUserData();
    if (data != null && mounted) {
      setState(() {
        _savedAddresses = data['addresses'] ?? [];
        _savedCards = data['paymentMethods'] ?? [];
        if (_savedAddresses.isNotEmpty)
          _selectedAddress = _savedAddresses.first;
        if (_savedCards.isNotEmpty) _selectedCard = _savedCards.first;
        _isLoadingData = false;
      });
    }
  }

  // GUARDA DIRECCIÓN EN FIRESTORE
  void _addNewAddress() async {
    if (_streetCtrl.text.isEmpty ||
        _cityCtrl.text.isEmpty ||
        _zipCtrl.text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Llene todos los campos correctamente. CP de 5 dígitos.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final newAddr = {
      'street': _streetCtrl.text,
      'city': _cityCtrl.text,
      'zip': _zipCtrl.text,
    };
    setState(() => _isLoadingData = true);
    await _profileRepo.addAddress(newAddr);
    _streetCtrl.clear();
    _cityCtrl.clear();
    _zipCtrl.clear();
    _loadUserData();
  }

  // GUARDA TARJETA EN FIRESTORE
  void _addNewCard() async {
    if (_cardHolderCtrl.text.isEmpty ||
        _cardNumberCtrl.text.length < 16 ||
        _expiryCtrl.text.length < 5 ||
        _cvvCtrl.text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifique los 16 dígitos, fecha (MM/YY) y CVV'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final newCard = {
      'holder': _cardHolderCtrl.text,
      'last4': _cardNumberCtrl.text.substring(12),
      'expiry': _expiryCtrl.text,
    };
    setState(() => _isLoadingData = true);
    await _profileRepo.addPaymentCard(newCard);
    _cardHolderCtrl.clear();
    _cardNumberCtrl.clear();
    _expiryCtrl.clear();
    _cvvCtrl.clear();
    _loadUserData();
  }

  void _processPayment() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione o agregue una dirección de envío.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedPaymentType == 'card' && _selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione o agregue una tarjeta.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cartCubit = context.read<CartCubit>();
    final cartState = cartCubit.state;
    final fullAddress =
        '${_selectedAddress!['street']}, ${_selectedAddress!['city']}, CP ${_selectedAddress!['zip']}';

    final List<OrderItem> orderItems = cartState.items.map((cartItem) {
      return OrderItem(
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        size: cartItem.selectedSize,
        quantity: cartItem.quantity,
        price: cartItem.product.price,
        image: cartItem.product.images.isNotEmpty
            ? cartItem.product.images.first
            : '',
      );
    }).toList();

    setState(() => _isProcessing = true);

    try {
      String finalPaymentMethod = '';
      String? oxxoRef;

      // LÓGICA PAYPAL
      if (_selectedPaymentType == 'paypal') {
        await _showPayPalSimulation();
        finalPaymentMethod = 'PayPal';
      }
      // LÓGICA OXXO
      else if (_selectedPaymentType == 'oxxo') {
        oxxoRef = _generateOxxoReference();
        finalPaymentMethod = 'OXXO Efectivo';
      }
      // LÓGICA TARJETA
      else {
        finalPaymentMethod = 'Tarjeta terminada en ${_selectedCard!['last4']}';
      }

      await _checkoutRepo.createOrder(
        orderItems: orderItems,
        total: cartState.totalPrice,
        address: fullAddress,
        paymentMethod: finalPaymentMethod,
      );

      if (!mounted) return;
      cartCubit.clearCart();

      if (_selectedPaymentType == 'oxxo') {
        _showOxxoInstructionsDialog(oxxoRef!);
      } else {
        _showSuccessDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _generateOxxoReference() {
    final rand = Random();
    String ref = '';
    for (int i = 0; i < 14; i++) {
      ref += rand.nextInt(10).toString();
    }
    return '${ref.substring(0, 4)} ${ref.substring(4, 8)} ${ref.substring(8, 12)} ${ref.substring(12, 14)}';
  }

  Future<void> _showPayPalSimulation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.paypal, color: Colors.blue, size: 50),
            SizedBox(height: 16),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Conectando de forma segura con PayPal...'),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.pop(context); // Cierra el loading de paypal
  }

  void _showOxxoInstructionsDialog(String reference) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Instrucciones de Pago OXXO',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Dicta este número de referencia al cajero. Tu pedido permanecerá PENDIENTE hasta que se confirme el pago.',
            ),
            const SizedBox(height: 16),
            Text(
              reference,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            // SIMULACIÓN VISUAL DE CÓDIGO DE BARRAS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                30,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: Random().nextDouble() * 4 + 1,
                  height: 50,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Entendido, volver al inicio'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('¡Compra Exitosa!'),
          ],
        ),
        content: const Text(
          'Tu orden ha sido autorizada y registrada con éxito.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text(
              'Volver al Inicio',
              style: TextStyle(color: AppColors.activeBlue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final cartState = context.watch<CartCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar Compra')),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DIRECCIONES
                  const Text(
                    '1. Dirección de Envío',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_savedAddresses.isNotEmpty)
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedAddress,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Mis Domicilios',
                      ),
                      items: _savedAddresses
                          .map(
                            (addr) => DropdownMenuItem(
                              value: addr as Map<String, dynamic>,
                              child: Text('${addr['street']}, ${addr['city']}'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedAddress = val),
                    ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text(
                      'Agregar nuevo domicilio',
                      style: TextStyle(color: AppColors.activeBlue),
                    ),
                    childrenPadding: const EdgeInsets.all(8),
                    children: [
                      TextField(
                        controller: _streetCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Calle y Número',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 100,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _cityCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Ciudad',
                                border: OutlineInputBorder(),
                              ),
                              maxLength: 50,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _zipCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'C.P.',
                                border: OutlineInputBorder(),
                              ),
                              maxLength: 5,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _addNewAddress,
                        child: const Text('Guardar Domicilio'),
                      ),
                    ],
                  ),
                  const Divider(height: 40),

                  // 2. MÉTODO DE PAGO
                  const Text(
                    '2. Método de Pago',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Opciones de Pago (Radio Buttons personalizados)
                  _buildPaymentType(
                    'Tarjeta de Crédito / Débito',
                    'card',
                    Icons.credit_card,
                  ),
                  if (_selectedPaymentType == 'card') ...[
                    if (_savedCards.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8.0,
                          left: 16,
                          right: 16,
                        ),
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedCard,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Mis Tarjetas',
                          ),
                          items: _savedCards
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c as Map<String, dynamic>,
                                  child: Text(
                                    '${c['holder']} - **** ${c['last4']}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCard = val),
                        ),
                      ),
                    ExpansionTile(
                      title: const Text(
                        'Agregar nueva tarjeta',
                        style: TextStyle(color: AppColors.activeBlue),
                      ),
                      childrenPadding: const EdgeInsets.all(8),
                      children: [
                        TextField(
                          controller: _cardHolderCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Titular de la Tarjeta',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 50,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cardNumberCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Número de Tarjeta (16 dígitos)',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 16,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _expiryCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Expira (MM/YY)',
                                  border: OutlineInputBorder(),
                                ),
                                maxLength: 5,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _cvvCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  border: OutlineInputBorder(),
                                ),
                                maxLength: 3,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _addNewCard,
                          child: const Text('Guardar Tarjeta Segura'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildPaymentType(
                    'Efectivo en OXXO (Autorización Pendiente)',
                    'oxxo',
                    Icons.storefront,
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentType('Pagar con PayPal', 'paypal', Icons.paypal),

                  const Divider(height: 40),

                  // 3. RESUMEN
                  const Text(
                    '3. Resumen de Orden',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total a pagar:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${cartState.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.activeBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _processPayment,
                      child: const Text('Confirmar y Pagar Ahora'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentType(String title, String typeValue, IconData icon) {
    final isSelected = _selectedPaymentType == typeValue;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentType = typeValue),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? AppColors.activeBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? AppColors.activeBlue : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                icon,
                color: isSelected ? AppColors.activeBlue : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
