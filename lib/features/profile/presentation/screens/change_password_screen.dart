import 'package:flutter/material.dart';
import 'package:red_cristiana/core/utils/app_error_helper.dart';
import 'package:red_cristiana/features/auth/data/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isSaving = false;
  bool obscure1 = true;
  bool obscure2 = true;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await AuthService.updatePassword(password);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudo actualizar la contraseña en este momento.'))),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar contraseña'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: passwordController,
              obscureText: obscure1,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure1 = !obscure1),
                  icon: Icon(obscure1 ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: confirmPasswordController,
              obscureText: obscure2,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure2 = !obscure2),
                  icon: Icon(obscure2 ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isSaving ? null : _save,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar nueva contraseña'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}