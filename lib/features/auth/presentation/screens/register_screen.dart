import 'package:flutter/material.dart';
import 'package:red_cristiana/features/auth/presentation/screens/church_registration_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String selectedRole = 'user';

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = response.user;

      if (user != null) {
        await Supabase.instance.client.from('profiles').insert({
          'id': user.id,
          'full_name': fullNameController.text.trim(),
          'role': selectedRole,
          'country': 'Ecuador',
          'city': '',
          'sector': '',
          'approval_status': selectedRole == 'church' ? 'pending' : 'approved',
        });
      }

      if (!mounted) return;

      if (selectedRole == 'church') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ChurchRegistrationScreen(
              userId: user!.id,
              userEmail: emailController.text.trim(),
            ),
          ),
              (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la cuenta: $e'),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu nombre';
    }
    if (value.trim().length < 3) {
      return 'Tu nombre es demasiado corto';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo electrónico';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa una contraseña';
    }
    if (value.trim().length < 6) {
      return 'Debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value.trim() != passwordController.text.trim()) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Widget _buildRoleCard({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selectedRole == value;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          selectedRole = value;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? const Color(0xFFEAF4FF)
              : Colors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isSelected
                  ? const Color(0xFF0D47A1)
                  : Colors.grey.shade200,
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF0D47A1),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Únete a Red Cristiana',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Crea tu cuenta y elige cómo deseas participar en la plataforma.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 28),

                _buildRoleCard(
                  value: 'user',
                  title: 'Persona',
                  subtitle: 'Buscar iglesias, eventos, ayuda espiritual y contenido cristiano.',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                _buildRoleCard(
                  value: 'church',
                  title: 'Iglesia',
                  subtitle: 'Registrar tu iglesia, publicar horarios, eventos y recibir contactos.',
                  icon: Icons.church_outlined,
                ),

                const SizedBox(height: 28),
                TextFormField(
                  controller: fullNameController,
                  validator: _validateName,
                  decoration: InputDecoration(
                    labelText: selectedRole == 'church'
                        ? 'Nombre del responsable'
                        : 'Nombre completo',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  validator: _validateConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: isLoading ? null : _register,
                    child: isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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