import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/login_screen.dart';
import '../../catalog/presentation/home_screen.dart';
import 'admin_products_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final AuthRepository _authRepo = AuthRepository();

  // Cambiamos la lista estática por una función que genere las vistas para permitir
  // que el Dashboard se refresque en tiempo real cada vez que entramos a él.
  List<Widget> _getAdminViews() {
    return [
      const _AdminSummaryView(), // Nueva vista analítica premium integrada abajo
      const AdminProductsScreen(),
      const AdminOrdersScreen(),
      const AdminUsersScreen(),
    ];
  }

  final List<String> _titles = [
    'Dashboard',
    'Inventario',
    'Pedidos',
    'Usuarios',
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  void _logout() async {
    await _authRepo.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin: ${_titles[_selectedIndex]}'),
        backgroundColor: AppColors.primaryBlue,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: AppColors.primaryBlue),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: AppColors.pureWhite,
                          size: 50,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Panel Administrativo',
                          style: TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.dashboard,
                      color: AppColors.activeBlue,
                    ),
                    title: const Text('Dashboard'),
                    selected: _selectedIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.inventory,
                      color: AppColors.activeBlue,
                    ),
                    title: const Text('Inventario'),
                    selected: _selectedIndex == 1,
                    onTap: () => _onItemTapped(1),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.shopping_bag,
                      color: AppColors.activeBlue,
                    ),
                    title: const Text('Pedidos'),
                    selected: _selectedIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.people,
                      color: AppColors.activeBlue,
                    ),
                    title: const Text('Usuarios'),
                    selected: _selectedIndex == 3,
                    onTap: () => _onItemTapped(3),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.storefront, color: Colors.green),
                    title: const Text(
                      'Ir a la Tienda',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _logout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: _getAdminViews()[_selectedIndex],
    );
  }
}

// =========================================================================
// WIDGET INTERNO: VISTA RESUMEN ANALÍTICA (DASHBOARD REAL CON FIRESTORE)
// =========================================================================
class _AdminSummaryView extends StatelessWidget {
  const _AdminSummaryView();

  // Consulta en paralelo todas las colecciones esenciales para armar el reporte matemático
  Future<Map<String, dynamic>> _getDashboardMetrics() async {
    final firestore = FirebaseFirestore.instance;

    final results = await Future.wait([
      firestore.collection('products').get(),
      firestore.collection('orders').get(),
      firestore.collection('users').get(),
    ]);

    final productsSnap = results[0];
    final ordersSnap = results[1];
    final usersSnap = results[2];

    double totalRevenue = 0.0;
    int pendingOrders = 0;

    for (var doc in ordersSnap.docs) {
      final data = doc.data();
      totalRevenue += (data['total'] ?? 0.0).toDouble();
      if (data['status'] == 'pending') {
        pendingOrders++;
      }
    }

    return {
      'totalProducts': productsSnap.docs.length,
      'totalOrders': ordersSnap.docs.length,
      'totalUsers': usersSnap.docs.length,
      'totalRevenue': totalRevenue,
      'pendingOrders': pendingOrders,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDashboardMetrics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.activeBlue),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar reporte: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final double revenue = data['totalRevenue'] ?? 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado estético
              const Text(
                'Resumen General de Operaciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Métricas clave calculadas a partir de la base de datos en tiempo real.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Tarjeta Destacada: Ingresos Totales de la app
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.activeBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INGRESOS BRUTOS TOTALES',
                          style: TextStyle(
                            color: AppColors.pureWhite.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Icon(
                          Icons.monetization_on,
                          color: AppColors.pureWhite,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$${revenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monto acumulado de todos los pedidos procesados',
                      style: TextStyle(
                        color: AppColors.pureWhite.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Grilla de Indicadores de Control (Cards de Métricas)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMetricCard(
                    title: 'Total Pedidos',
                    value: '${data['totalOrders']}',
                    subtitle: 'Historial de ventas',
                    icon: Icons.shopping_bag,
                    color: AppColors.activeBlue,
                  ),
                  _buildMetricCard(
                    title: 'Por Autorizar',
                    value: '${data['pendingOrders']}',
                    subtitle: 'Efectivo OXXO / Nuevos',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  _buildMetricCard(
                    title: 'Productos',
                    value: '${data['totalProducts']}',
                    subtitle: 'Artículos en catálogo',
                    icon: Icons.inventory_2,
                    color: AppColors.primaryBlue,
                  ),
                  _buildMetricCard(
                    title: 'Comunidad',
                    value: '${data['totalUsers']}',
                    subtitle: 'Clientes registrados',
                    icon: Icons.people_alt,
                    color: Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Sección Informativa Inferior (Consejo de Gestión)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                      size: 30,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sugerencia de Control',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Recuerda verificar periódicamente el apartado de "Pedidos por Autorizar" para activar los envíos correspondientes a los tickets liquidados en efectivo.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
