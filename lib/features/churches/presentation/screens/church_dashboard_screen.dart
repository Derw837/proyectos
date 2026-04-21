import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_dashboard_service.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_events_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_feed_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_members_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_notify_members_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_posts_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_prayer_requests_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_profile_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_profile_videos_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_schedules_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_spiritual_help_screen.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';

class ChurchDashboardScreen extends StatefulWidget {
  const ChurchDashboardScreen({super.key});

  @override
  State<ChurchDashboardScreen> createState() => _ChurchDashboardScreenState();
}

class _ChurchDashboardScreenState extends State<ChurchDashboardScreen> {
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF152033);
  static const Color _textSoft = Color(0xFF6B7280);

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

  String _getInitials(String text) {
    final parts = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'IG';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: _textSoft,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220D47A1),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Center(
                  child: Text(
                    _getInitials(churchName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel pastoral',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Centro de administración',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Activa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            churchName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroChip(
                icon: Icons.groups_outlined,
                text: '$membersCount miembros',
              ),
              _heroChip(
                icon: Icons.favorite_border,
                text: '$likesCount me gusta',
              ),
              _heroChip(
                icon: Icons.auto_awesome_outlined,
                text: 'Área pastoral',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: _primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _textSoft,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openScreen(screen),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EEF7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textDark,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textSoft,
                fontSize: 12.2,
                height: 1.25,
              ),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openScreen(screen),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EEF7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: _primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _textSoft,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F5FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: _textSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _heroCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.favorite_outline,
                  title: 'Me gusta',
                  value: '$likesCount',
                  subtitle: 'Apoyo recibido',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.groups_2_outlined,
                  title: 'Miembros',
                  value: '$membersCount',
                  subtitle: 'Comunidad activa',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle(
            'Administración',
            'Actualiza y organiza toda la información de tu iglesia.',
          ),
          _optionCard(
            title: 'Peticiones de oración',
            subtitle: 'Revisa y responde las peticiones recibidas.',
            icon: Icons.volunteer_activism_outlined,
            screen: const ChurchPrayerRequestsScreen(),
          ),
          _optionCard(
            title: 'Editar perfil de iglesia',
            subtitle: 'Nombre, contacto, ubicación, descripción y donaciones.',
            icon: Icons.edit_outlined,
            screen: const ChurchProfileManageScreen(),
          ),
          _optionCard(
            title: 'Administrar horarios',
            subtitle: 'Cultos, reuniones, actividades y horarios semanales.',
            icon: Icons.schedule_outlined,
            screen: const ChurchSchedulesManageScreen(),
          ),
          _optionCard(
            title: 'Publicar eventos',
            subtitle: 'Campañas, conciertos, conferencias y actividades.',
            icon: Icons.event_available_outlined,
            screen: const ChurchEventsManageScreen(),
          ),
          _optionCard(
            title: 'Publicaciones y fotos',
            subtitle: 'Mensajes, novedades, imágenes y contenido visual.',
            icon: Icons.photo_library_outlined,
            screen: const ChurchPostsManageScreen(),
          ),
          _optionCard(
            title: 'Videos de mi iglesia',
            subtitle: 'YouTube y otros enlaces de video para la comunidad.',
            icon: Icons.ondemand_video_outlined,
            screen: const ChurchProfileVideosManageScreen(),
          ),
          _optionCard(
            title: 'Apoyo espiritual',
            subtitle: 'Configura el botón de ayuda espiritual y su destino.',
            icon: Icons.volunteer_activism_outlined,
            screen: const ChurchSpiritualHelpScreen(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChurchHeaderShell(
      child: Scaffold(
        backgroundColor: _surface,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _dashboardContent(),
      ),
    );
  }
}