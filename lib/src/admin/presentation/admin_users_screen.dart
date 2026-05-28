import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../auth/domain/user_model.dart';
import '../data/admin_repository.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminRepository _adminRepo = AdminRepository();
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = _adminRepo.getAllUsers();
    });
  }

  void _toggleRole(UserModel user) async {
    final newRole = user.role == 'admin' ? 'client' : 'admin';
    await _adminRepo.updateUserRole(user.uid, newRole);
    _refreshUsers();
  }

  void _deleteUser(String userId) async {
    await _adminRepo.deleteUserDoc(userId);
    _refreshUsers();
  }

  // ¡NUEVO! Visor de datos sensibles del cliente
  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Información de ${user.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const Divider(height: 24),
              const Text(
                'Domicilios Guardados:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (user.addresses.isEmpty)
                const Text(
                  'Sin domicilios',
                  style: TextStyle(color: Colors.grey),
                ),
              ...user.addresses.map(
                (a) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on),
                  title: Text('${a['street']}, ${a['city']}'),
                  subtitle: Text('CP: ${a['zip']}'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Métodos de Pago:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (user.paymentMethods.isEmpty)
                const Text(
                  'Sin tarjetas',
                  style: TextStyle(color: Colors.grey),
                ),
              ...user.paymentMethods.map(
                (c) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.credit_card),
                  title: Text('${c['holder']}'),
                  subtitle: Text('**** ${c['last4']}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text('No hay usuarios.'));

        final users = snapshot.data!;

        return ListView.builder(
          itemCount: users.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final user = users[index];
            final isAdmin = user.role == 'admin';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAdmin
                      ? AppColors.activeBlue
                      : Colors.grey.shade300,
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: isAdmin ? AppColors.pureWhite : Colors.black54,
                  ),
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(user.email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: AppColors.activeBlue,
                      ),
                      onPressed: () =>
                          _showUserDetails(user), // Ver domicilios y tarjetas
                    ),
                    IconButton(
                      icon: Icon(
                        isAdmin ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                      ),
                      onPressed: () => _toggleRole(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUser(user.uid),
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
