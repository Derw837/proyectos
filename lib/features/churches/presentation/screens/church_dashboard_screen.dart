import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_dashboard_service.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_events_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_members_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_posts_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_profile_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_profile_videos_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_schedules_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_spiritual_help_screen.dart';

class ChurchDashboardScreen extends StatefulWidget {
  const ChurchDashboardScreen({super.key});

  @override
  State<ChurchDashboardScreen> createState() => _ChurchDashboardScreenState();
}

class _ChurchDashboardScreenState extends State<ChurchDashboardScreen> {
  bool isLoading = true;
  int likesCount = 0;
  int membersCount = 0;
  String churchName = 'Mi iglesia';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final data = await ChurchDashboardService.getDashboardStats();

      final church = data['church'] as Map<String, dynamic>?;

      if (!mounted) return;

      setState(() {
        likesCount = data['likes_count'] ?? 0;
        membersCount = data['members_count'] ?? 0;
        churchName = church?['church_name']?.toString() ?? 'Mi iglesia';
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _card({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget screen,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
        await _loadStats();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFEAF4FF),
              child: Icon(icon, color: const Color(0xFF0D47A1)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0D47A1)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Panel de iglesia'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0D47A1),
                  Color(0xFF1565C0),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  churchName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _statCard(
                '$likesCount',
                'Me gusta',
                Icons.favorite_border,
              ),
              const SizedBox(width: 12),
              _statCard(
                '$membersCount',
                'Miembros',
                Icons.groups_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _card(
            context: context,
            title: 'Editar perfil de iglesia',
            subtitle: 'Actualiza datos, dirección, contacto y donaciones.',
            icon: Icons.edit_outlined,
            screen: const ChurchProfileManageScreen(),
          ),
          _card(
            context: context,
            title: 'Administrar horarios',
            subtitle: 'Agrega cultos, reuniones, vigilias y horarios semanales.',
            icon: Icons.schedule_outlined,
            screen: const ChurchSchedulesManageScreen(),
          ),
          _card(
            context: context,
            title: 'Publicar eventos',
            subtitle: 'Agrega campañas, conciertos y actividades especiales.',
            icon: Icons.event_available_outlined,
            screen: const ChurchEventsManageScreen(),
          ),
          _card(
            context: context,
            title: 'Publicaciones y fotos',
            subtitle: 'Comparte imágenes, mensajes y novedades.',
            icon: Icons.photo_library_outlined,
            screen: const ChurchPostsManageScreen(),
          ),
          _card(
            context: context,
            title: 'Videos de mi iglesia',
            subtitle: 'Publica enlaces de YouTube u otros videos en tu perfil.',
            icon: Icons.ondemand_video_outlined,
            screen: const ChurchProfileVideosManageScreen(),
          ),
          _card(
            context: context,
            title: 'Miembros de la iglesia',
            subtitle: 'Consulta los usuarios que marcaron Soy miembro.',
            icon: Icons.groups_outlined,
            screen: const ChurchMembersScreen(),
          ),
          _card(
            context: context,
            title: 'Configurar apoyo espiritual',
            subtitle: 'Personaliza el botón de ayuda espiritual.',
            icon: Icons.volunteer_activism_outlined,
            screen: const ChurchSpiritualHelpScreen(),
          ),
        ],
      ),
    );
  }
}