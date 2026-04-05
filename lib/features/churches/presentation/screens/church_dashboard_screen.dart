import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_dashboard_service.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_events_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_members_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_notify_members_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_posts_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_prayer_requests_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_profile_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_profile_videos_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_schedules_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_spiritual_help_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_feed_screen.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';

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

  Future<void> _openScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    await _loadStats();
  }

  Widget _statCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0D47A1), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required String title,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openScreen(screen),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _optionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget screen,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openScreen(screen),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(16),
              ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.35,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChurchHeaderShell(
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Panel pastoral',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    churchName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Administra tu iglesia y da seguimiento a tu comunidad.',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.35,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _statCard(
                  value: '$likesCount',
                  label: 'Me gusta',
                  icon: Icons.favorite_border,
                ),
                const SizedBox(width: 10),
                _statCard(
                  value: '$membersCount',
                  label: 'Miembros',
                  icon: Icons.groups_outlined,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _sectionTitle('Accesos rápidos'),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _quickAction(
                  title: 'Ver todas las\nPublicaciones',
                  icon: Icons.public,
                  color: const Color(0xFF0D47A1),
                  screen: const ChurchFeedScreen(),
                ),
                _quickAction(
                  title: 'Ver\nmiembros',
                  icon: Icons.groups_outlined,
                  color: const Color(0xFF2E7D32),
                  screen: const ChurchMembersScreen(),
                ),
                _quickAction(
                  title: 'Notificar\nmiembros',
                  icon: Icons.notifications_active_outlined,
                  color: const Color(0xFF6A1B9A),
                  screen: const ChurchNotifyMembersScreen(),
                ),
                _quickAction(
                  title: 'Peticiones\nde oración',
                  icon: Icons.volunteer_activism_outlined,
                  color: const Color(0xFFEF6C00),
                  screen: const ChurchPrayerRequestsScreen(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _sectionTitle('Administración'),
            _optionCard(
              title: 'Editar perfil de iglesia',
              subtitle: 'Actualiza nombre, dirección, contacto y donaciones.',
              icon: Icons.edit_outlined,
              screen: const ChurchProfileManageScreen(),
            ),
            _optionCard(
              title: 'Administrar horarios',
              subtitle: 'Agrega cultos, reuniones y horarios semanales.',
              icon: Icons.schedule_outlined,
              screen: const ChurchSchedulesManageScreen(),
            ),
            _optionCard(
              title: 'Publicar eventos',
              subtitle: 'Agrega campañas, conciertos y actividades.',
              icon: Icons.event_available_outlined,
              screen: const ChurchEventsManageScreen(),
            ),
            _optionCard(
              title: 'Publicaciones y fotos',
              subtitle: 'Comparte imágenes, mensajes y novedades.',
              icon: Icons.photo_library_outlined,
              screen: const ChurchPostsManageScreen(),
            ),
            _optionCard(
              title: 'Videos de mi iglesia',
              subtitle: 'Publica enlaces de YouTube u otros videos.',
              icon: Icons.ondemand_video_outlined,
              screen: const ChurchProfileVideosManageScreen(),
            ),
            _optionCard(
              title: 'Configurar apoyo espiritual',
              subtitle: 'Personaliza el botón de ayuda espiritual.',
              icon: Icons.volunteer_activism_outlined,
              screen: const ChurchSpiritualHelpScreen(),
            ),
          ],
        ),
      ),
        ),
    );
  }
}