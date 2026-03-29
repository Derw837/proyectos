import 'package:flutter/material.dart';

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D1B2A),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEAF4FF),
            radius: 24,
            child: Icon(icon, color: const Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Red Cristiana',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Encuentra iglesias, ayuda espiritual, eventos y contenido cristiano en un solo lugar.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1565C0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Conectando personas e iglesias para servir, apoyar y compartir la fe.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              _buildSectionTitle('Accesos rápidos'),

              _buildFeatureCard(
                icon: Icons.church,
                title: 'Buscar iglesias',
                subtitle: 'Descubre iglesias por país, ciudad y sector.',
                backgroundColor: const Color(0xFF1565C0),
              ),
              _buildFeatureCard(
                icon: Icons.favorite_outline,
                title: 'Ayuda espiritual',
                subtitle: 'Encuentra acompañamiento y apoyo cuando lo necesites.',
                backgroundColor: const Color(0xFF2E7D32),
              ),
              _buildFeatureCard(
                icon: Icons.campaign_outlined,
                title: 'Eventos y campañas',
                subtitle: 'Mira conciertos, congresos, vigilias y actividades especiales.',
                backgroundColor: const Color(0xFF8E24AA),
              ),

              const SizedBox(height: 16),
              _buildSectionTitle('Explora más'),

              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildMiniCard(
                      title: 'Radios online',
                      subtitle: 'Escucha emisoras cristianas desde la app.',
                      icon: Icons.radio,
                    ),
                    _buildMiniCard(
                      title: 'Predicaciones',
                      subtitle: 'Videos y mensajes para edificación espiritual.',
                      icon: Icons.play_circle_outline,
                    ),
                    _buildMiniCard(
                      title: 'Jornadas de oración',
                      subtitle: 'Únete a momentos especiales de intercesión.',
                      icon: Icons.volunteer_activism_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}