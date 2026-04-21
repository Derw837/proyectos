import 'package:flutter/material.dart';
import 'package:red_cristiana/core/utils/app_error_helper.dart';
import 'package:red_cristiana/core/utils/user_helper.dart';
import 'package:red_cristiana/features/auth/presentation/screens/church_registration_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/user_main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:red_cristiana/features/auth/presentation/screens/login_screen.dart';
import 'package:red_cristiana/core/widgets/latam_location_fields.dart';


class CompleteGoogleSignupScreen extends StatefulWidget {
  const CompleteGoogleSignupScreen({super.key});

  @override
  State<CompleteGoogleSignupScreen> createState() =>
      _CompleteGoogleSignupScreenState();
}

class _CompleteGoogleSignupScreenState
    extends State<CompleteGoogleSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final countryController = TextEditingController(text: 'Ecuador');
  final cityController = TextEditingController();
  final sectorController = TextEditingController();

  bool isLoading = false;
  String selectedRole = 'user';

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    fullNameController.text =
        metadata['full_name']?.toString() ??
        metadata['name']?.toString() ??
        user?.email?.split('@').first ??
        '';
  }

  @override
  void dispose() {
    fullNameController.dispose();
    countryController.dispose();
    cityController.dispose();
    sectorController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $label';
    }
    return null;
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return;

    setState(() => isLoading = true);

    try {
      if (selectedRole == 'user') {
        await UserHelper.createUserProfile(
          fullName: fullNameController.text.trim(),
          country: countryController.text.trim(),
          city: cityController.text.trim(),
          sector: sectorController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const UserMainNavigationScreen(),
          ),
          (route) => false,
        );
      } else {
        await UserHelper.createChurchProfilePlaceholder(
          fullName: fullNameController.text.trim(),
          country: countryController.text.trim(),
          city: cityController.text.trim(),
          sector: sectorController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ChurchRegistrationScreen(
              userId: authUser.id,
              userEmail: authUser.email ?? '',
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            await AppErrorHelper.friendlyMessage(
              e,
              fallback: 'No se pudo completar el registro en este momento.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _roleCard({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selectedRole == value;

    return InkWell(
      onTap: () => setState(() => selectedRole = value),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected
                  ? const Color(0xFF0D47A1)
                  : Colors.grey.shade200,
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF0D47A1)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Completar registro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();

            if (!context.mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginScreen(showBack: true),
              ),
                  (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Antes de continuar',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Indícanos si entrarás como usuario o como iglesia.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: fullNameController,
                  validator: (v) => _required(v, 'tu nombre'),
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                LatamLocationFields(
                  countryController: countryController,
                  cityController: cityController,
                  sectorController: sectorController,
                  requiredValidator: _required,
                  decorationBuilder: (label, icon) {
                    return InputDecoration(
                      labelText: label,
                      prefixIcon: Icon(icon),
                      border: const OutlineInputBorder(),
                    );
                  },
                ),
                const SizedBox(height: 22),
                _roleCard(
                  value: 'user',
                  title: 'Usuario',
                  subtitle: 'Entrar directamente a la app.',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _roleCard(
                  value: 'church',
                  title: 'Iglesia',
                  subtitle: 'Completar solicitud y esperar aprobación.',
                  icon: Icons.church_outlined,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _continue,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}