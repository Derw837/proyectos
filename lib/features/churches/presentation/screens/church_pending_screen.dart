import 'package:flutter/material.dart';
import 'package:red_cristiana/features/auth/presentation/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchPendingScreen extends StatelessWidget {
  const ChurchPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_bottom,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'Tu iglesia está en revisión',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nuestro equipo está verificando la información. Te notificaremos cuando sea aprobada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                },
                child: const Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}