import 'package:flutter/material.dart';
import 'package:red_cristiana/features/auth/presentation/screens/login_screen.dart';
import 'package:red_cristiana/features/profile/data/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:red_cristiana/features/notifications/presentation/screens/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final fullNameController = TextEditingController();
  final countryController = TextEditingController();
  final cityController = TextEditingController();
  final sectorController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  String role = '';
  String approvalStatus = '';
  String email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    countryController.dispose();
    cityController.dispose();
    sectorController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      final profile = await ProfileService.getMyProfile();

      if (!mounted) return;

      email = authUser?.email ?? '';

      if (profile != null) {
        fullNameController.text = profile['full_name']?.toString() ?? '';
        countryController.text = profile['country']?.toString() ?? '';
        cityController.text = profile['city']?.toString() ?? '';
        sectorController.text = profile['sector']?.toString() ?? '';
        role = profile['role']?.toString() ?? '';
        approvalStatus = profile['approval_status']?.toString() ?? '';
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando perfil: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      isSaving = true;
    });

    try {
      await ProfileService.updateMyProfile(
        fullName: fullNameController.text.trim(),
        country: countryController.text.trim(),
        city: cityController.text.trim(),
        sector: sectorController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando perfil: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    }
  }

  String _roleLabel(String value) {
    switch (value) {
      case 'church':
        return 'Iglesia';
      case 'admin':
        return 'Administrador';
      default:
        return 'Usuario';
    }
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      case 'suspended':
        return 'Suspendido';
      default:
        return 'No definido';
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _profileCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _profileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0D47A1)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }

  void _showEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'Editar perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: fullNameController,
                  decoration: _decoration('Nombre', Icons.person),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: countryController,
                  decoration: _decoration('País', Icons.public),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  decoration: _decoration('Ciudad', Icons.location_city),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sectorController,
                  decoration: _decoration('Sector', Icons.map),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                      await _saveProfile();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Guardar cambios'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final fullName = fullNameController.text.trim().isEmpty
        ? 'Usuario'
        : fullNameController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _roleLabel(role),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _profileCard(
                title: 'Información',
                children: [
                  _profileItem(Icons.public, 'País', countryController.text),
                  _profileItem(
                    Icons.location_city,
                    'Ciudad',
                    cityController.text,
                  ),
                  _profileItem(Icons.map, 'Sector', sectorController.text),
                ],
              ),
              const SizedBox(height: 14),
              _profileCard(
                title: 'Estado de cuenta',
                children: [
                  _profileItem(
                    Icons.verified_user_outlined,
                    'Estado',
                    _statusLabel(approvalStatus),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showEditModal,
                  icon: const Icon(Icons.edit),
                  label: const Text(
                    'Editar perfil',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _menuTile(
                icon: Icons.notifications_none,
                title: 'Mis notificaciones',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _menuTile(
                icon: Icons.logout,
                title: 'Cerrar sesión',
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                        (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}