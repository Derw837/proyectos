import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TvProfileScreen extends StatelessWidget {
  const TvProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar sesión.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return SafeArea(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 840),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x22FFFFFF)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_circle_rounded,
                size: 90,
                color: Color(0xFF4FC3F7),
              ),
              const SizedBox(height: 18),
              const Text(
                'Tu perfil',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF172235),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Correo',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.email ?? 'Sin correo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Más adelante aquí pondremos más ajustes de cuenta, preferencias y opciones exclusivas para TV.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              _TvProfileButton(
                label: 'Cerrar sesión',
                icon: Icons.logout_rounded,
                filled: true,
                onTap: () => _signOut(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TvProfileButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _TvProfileButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_TvProfileButton> createState() => _TvProfileButtonState();
}

class _TvProfileButtonState extends State<_TvProfileButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        setState(() {
          _focused = value;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: widget.filled
                ? const Color(0xFF1E88FF)
                : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _focused
                  ? const Color(0xFF4FC3F7)
                  : const Color(0x24FFFFFF),
              width: _focused ? 2 : 1,
            ),
            boxShadow: _focused
                ? [
              BoxShadow(
                color: const Color(0xFF4FC3F7).withValues(alpha: 0.20),
                blurRadius: 18,
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}