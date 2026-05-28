import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/network_image.dart';
import '../../checkout/domain/order_model.dart';
import '../data/admin_repository.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final AdminRepository _adminRepo = AdminRepository();
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  // ¡AQUÍ ESTÁ LA CORRECCIÓN DEL BUG DE SETSTATE!
  void _refreshOrders() {
    setState(() {
      _ordersFuture = _adminRepo.getAllOrders();
    });
  }

  void _updateStatus(OrderModel order, String newStatus) async {
    await _adminRepo.updateOrderStatus(order.id, newStatus);
    _refreshOrders();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderModel>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text('No hay pedidos registrados.'));

        final orders = snapshot.data!;

        return ListView.builder(
          itemCount: orders.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final order = orders[index];
            final dateStr =
                '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 0,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
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
                    const SizedBox(height: 8),
                    Text(
                      'Total: \$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.activeBlue,
                      ),
                    ),
                    Text(
                      'Envío: ${order.address}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (order.oxxoReference != null)
                      Text(
                        'OXXO Ref: ${order.oxxoReference}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
                        DropdownButton<String>(
                          value: order.status,
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                          underline: Container(
                            height: 2,
                            color: AppColors.activeBlue,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue != order.status)
                              _updateStatus(order, newValue);
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('Pendiente'),
                            ),
                            DropdownMenuItem(
                              value: 'shipped',
                              child: Text('Enviado'),
                            ),
                            DropdownMenuItem(
                              value: 'delivered',
                              child: Text('Entregado'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            await _adminRepo.deleteOrder(order.id);
                            _refreshOrders();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
