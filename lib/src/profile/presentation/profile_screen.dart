import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/network_image.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/login_screen.dart';
import '../../checkout/domain/order_model.dart';
import '../data/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();
  final AuthRepository _authRepo = AuthRepository();

  late Future<List<OrderModel>> _ordersFuture;
  late Future<Map<String, dynamic>?> _userDataFuture;
  User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
      _ordersFuture = _profileRepo.getMyOrders();
      _userDataFuture = _profileRepo.getUserData();
    });
  }

  void _logout() async {
    await _authRepo.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // DIÁLOGO PARA EDITAR PERFIL BÁSICO
  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(
      text: _currentUser?.displayName ?? '',
    );
    final photoCtrl = TextEditingController(); // Puede ser URL de Github

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre Completo'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: photoCtrl,
              decoration: const InputDecoration(
                labelText: 'Foto (Nombre Github o URL)',
                hintText: 'ej. mi_foto.png',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                await _profileRepo.updateBasicProfile(
                  nameCtrl.text.trim(),
                  photoCtrl.text.trim(),
                );
                if (mounted) Navigator.pop(context);
                _refreshData();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // DIÁLOGO PARA AÑADIR DOMICILIO
  void _showAddAddressDialog() {
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final zipCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Domicilio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: streetCtrl,
              decoration: const InputDecoration(labelText: 'Calle y Número'),
            ),
            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            TextField(
              controller: zipCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'C.P.'),
              maxLength: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (streetCtrl.text.isNotEmpty &&
                  cityCtrl.text.isNotEmpty &&
                  zipCtrl.text.isNotEmpty) {
                await _profileRepo.addAddress({
                  'street': streetCtrl.text,
                  'city': cityCtrl.text,
                  'zip': zipCtrl.text,
                });
                if (mounted) Navigator.pop(context);
                _refreshData();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // DIÁLOGO PARA AÑADIR TARJETA
  void _showAddCardDialog() {
    final holderCtrl = TextEditingController();
    final numCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Tarjeta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: holderCtrl,
              decoration: const InputDecoration(labelText: 'Titular'),
            ),
            TextField(
              controller: numCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '16 Dígitos'),
              maxLength: 16,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expCtrl,
                    decoration: const InputDecoration(labelText: 'MM/YY'),
                    maxLength: 5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: cvvCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'CVV'),
                    maxLength: 3,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (numCtrl.text.length >= 15) {
                await _profileRepo.addPaymentCard({
                  'holder': holderCtrl.text,
                  'last4': numCtrl.text.substring(numCtrl.text.length - 4),
                  'expiry': expCtrl.text,
                });
                if (mounted) Navigator.pop(context);
                _refreshData();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // DATOS DEL USUARIO Y FOTO
            Container(
              width: double.infinity,
              color: AppColors.primaryBlue,
              padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.pureWhite,
                        child: ClipOval(
                          child: SizedBox(
                            width: 95,
                            height: 95,
                            child:
                                _currentUser?.photoURL != null &&
                                    _currentUser!.photoURL!.isNotEmpty
                                ? CustomNetworkImage(
                                    imageName: _currentUser!.photoURL!,
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppColors.primaryBlue,
                                  ),
                          ),
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: AppColors.activeBlue,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                          onPressed: _showEditProfileDialog,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentUser?.displayName ?? 'Usuario',
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentUser?.email ?? '',
                    style: TextStyle(
                      color: AppColors.pureWhite.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // GESTIÓN DE DOMICILIOS Y TARJETAS
            FutureBuilder<Map<String, dynamic>?>(
              future: _userDataFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final data = snapshot.data!;
                final addresses = data['addresses'] as List<dynamic>? ?? [];
                final cards = data['paymentMethods'] as List<dynamic>? ?? [];

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mis Domicilios',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: AppColors.activeBlue,
                            ),
                            onPressed: _showAddAddressDialog,
                          ),
                        ],
                      ),
                      if (addresses.isEmpty)
                        const Text(
                          'Sin domicilios',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ...addresses.map(
                        (a) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on),
                          title: Text('${a['street']}, ${a['city']}'),
                          subtitle: Text('CP: ${a['zip']}'),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mis Tarjetas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: AppColors.activeBlue,
                            ),
                            onPressed: _showAddCardDialog,
                          ),
                        ],
                      ),
                      if (cards.isEmpty)
                        const Text(
                          'Sin tarjetas',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ...cards.map(
                        (c) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.credit_card),
                          title: Text('${c['holder']}'),
                          subtitle: Text(
                            '**** ${c['last4']} - Exp: ${c['expiry']}',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(thickness: 4, color: AppColors.background),

            // HISTORIAL DE PEDIDOS
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.history, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text(
                    'Historial de Pedidos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<List<OrderModel>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const CircularProgressIndicator();
                if (!snapshot.hasData || snapshot.data!.isEmpty)
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No hay compras.'),
                  );
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) =>
                      _buildOrderCard(snapshot.data![index]),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    Color statusColor = order.status == 'shipped'
        ? Colors.blue
        : (order.status == 'delivered' ? Colors.green : Colors.orange);
    String statusText = order.status == 'shipped'
        ? 'Enviado'
        : (order.status == 'delivered' ? 'Entregado' : 'Pendiente');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ...${order.id.substring(order.id.length - 6)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: item.image.isNotEmpty
                            ? CustomNetworkImage(imageName: item.image)
                            : const Icon(Icons.image),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                          ),
                          Text(
                            'Talla: ${item.size} | Cant: ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.activeBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
