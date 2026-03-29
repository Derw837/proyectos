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

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0D47A1), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: Color(0xFFEAF4FF),
                      child: Icon(
                        Icons.person,
                        size: 36,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      fullNameController.text.trim().isEmpty
                          ? 'Usuario'
                          : fullNameController.text.trim(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _infoChip(
                icon: Icons.badge_outlined,
                label: 'Tipo de cuenta',
                value: _roleLabel(role),
              ),
              const SizedBox(height: 12),
              _infoChip(
                icon: Icons.verified_user_outlined,
                label: 'Estado',
                value: _statusLabel(approvalStatus),
              ),

              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: fullNameController,
                      decoration:
                      _decoration('Nombre completo', Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: countryController,
                      decoration: _decoration('País', Icons.public),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: cityController,
                      decoration:
                      _decoration('Ciudad', Icons.location_city),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: sectorController,
                      decoration:
                      _decoration('Sector', Icons.map_outlined),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isSaving ? null : _saveProfile,
                        child: isSaving
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Guardar cambios',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading: const Icon(Icons.notifications_none),
                title: const Text('Mis notificaciones'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
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

              const SizedBox(height: 20),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
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