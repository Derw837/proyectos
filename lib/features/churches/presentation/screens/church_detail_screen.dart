import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_public_service.dart';
import 'package:red_cristiana/features/churches/data/models/church_model.dart';
import 'package:red_cristiana/features/home/presentation/screens/user_main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ChurchDetailScreen extends StatefulWidget {
  final ChurchModel church;

  const ChurchDetailScreen({
    super.key,
    required this.church,
  });

  @override
  State<ChurchDetailScreen> createState() => _ChurchDetailScreenState();
}

class _ChurchDetailScreenState extends State<ChurchDetailScreen> {
  bool isLoadingSchedules = true;
  bool isLoadingStats = true;

  List<Map<String, dynamic>> schedules = [];

  int likesCount = 0;
  int membersCount = 0;
  bool likedByMe = false;
  bool memberByMe = false;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
    _loadStats();
  }

  int _dayOrder(String day) {
    final normalized = day.trim().toLowerCase();

    const order = {
      'domingo': 0,
      'lunes': 1,
      'martes': 2,
      'miercoles': 3,
      'miércoles': 3,
      'jueves': 4,
      'viernes': 5,
      'sabado': 6,
      'sábado': 6,
    };

    return order[normalized] ?? 99;
  }

  Future<void> _loadSchedules() async {
    try {
      final response = await Supabase.instance.client
          .from('church_schedules')
          .select()
          .eq('church_id', widget.church.id)
          .order('created_at');

      if (!mounted) return;

      final loadedSchedules = List<Map<String, dynamic>>.from(response);

      loadedSchedules.sort((a, b) {
        final dayA = a['day_name']?.toString() ?? '';
        final dayB = b['day_name']?.toString() ?? '';

        final orderA = _dayOrder(dayA);
        final orderB = _dayOrder(dayB);

        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }

        final startA = a['start_time']?.toString() ?? '';
        final startB = b['start_time']?.toString() ?? '';
        return startA.compareTo(startB);
      });

      setState(() {
        schedules = loadedSchedules;
        isLoadingSchedules = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoadingSchedules = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ChurchPublicService.getChurchStats(widget.church.id);

      if (!mounted) return;

      setState(() {
        likesCount = stats['likes_count'] ?? 0;
        membersCount = stats['members_count'] ?? 0;
        likedByMe = stats['liked_by_me'] ?? false;
        memberByMe = stats['member_by_me'] ?? false;
        isLoadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoadingStats = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    try {
      await ChurchPublicService.toggleChurchLike(widget.church.id);

      if (!mounted) return;
      await _loadStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en Me gusta: $e')),
      );
    }
  }

  Future<void> _toggleMember() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('Debes iniciar sesión');
      }

      final current = await client
          .from('church_memberships')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (current != null) {
        final currentChurchId = current['church_id'].toString();

        if (currentChurchId == widget.church.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ya eres miembro de esta iglesia')),
          );
          return;
        }

        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cambiar membresía'),
            content: const Text(
              'Ya eres miembro de otra iglesia.\n¿Quieres cambiar a esta?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Cambiar'),
              ),
            ],
          ),
        );

        if (!mounted) return;
        if (confirm != true) return;

        await client
            .from('church_memberships')
            .delete()
            .eq('user_id', user.id);

        if (!mounted) return;
      }

      await client.from('church_memberships').insert({
        'user_id': user.id,
        'church_id': widget.church.id,
      });

      if (!mounted) return;

      await _loadStats();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ahora eres miembro de esta iglesia')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de membresía: $e')),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    var value = url.trim();
    if (value.isEmpty) return;

    if (!value.startsWith('http://') &&
        !value.startsWith('https://') &&
        !value.startsWith('mailto:') &&
        !value.startsWith('tel:')) {
      value = 'https://$value';
    }

    final uri = Uri.tryParse(value);

    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El enlace de apoyo espiritual no es válido'),
        ),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    if (phone.trim().isEmpty) return;
    final cleaned = phone.replaceAll(' ', '');
    await _openUrl('https://wa.me/$cleaned');
  }

  void _openChurchFeed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserMainNavigationScreen(
          initialIndex: 0,
          initialFeedChurchId: widget.church.id,
          initialFeedChurchName: widget.church.churchName,
          initialFeedTab: 'all',
        ),
      ),
    );
  }

  void _openChurchEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserMainNavigationScreen(
          initialIndex: 2,
          initialEventsChurchId: widget.church.id,
          initialEventsChurchName: widget.church.churchName,
        ),
      ),
    );
  }

  void _openChurchLocation() {
    final address = widget.church.address.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta iglesia no tiene dirección registrada'),
        ),
      );
      return;
    }

    final encoded = Uri.encodeComponent(address);
    _openUrl('https://www.google.com/maps/search/?api=1&query=$encoded');
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      leading: Icon(icon, color: const Color(0xFF0D47A1)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [child],
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedules() {
    if (schedules.isEmpty) {
      return const Text(
        'No hay horarios registrados.',
        style: TextStyle(color: Colors.black54),
      );
    }

    return Column(
      children: schedules.map((schedule) {
        final day = schedule['day_name']?.toString() ?? '';
        final name = schedule['service_name']?.toString() ?? '';
        final start = schedule['start_time']?.toString() ?? '';
        final end = schedule['end_time']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFF0D47A1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (name.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                    if (start.isNotEmpty || end.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        end.isNotEmpty ? '$start - $end' : start,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0D47A1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final church = widget.church;
    final location = [
      if (church.city.isNotEmpty) church.city,
      if (church.country.isNotEmpty) church.country,
    ].join(', ');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF0D47A1),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                church.churchName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: church.coverUrl != null && church.coverUrl!.isNotEmpty
                  ? Image.network(
                church.coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF0D47A1),
                ),
              )
                  : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1565C0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (church.logoUrl != null && church.logoUrl!.isNotEmpty)
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x11000000),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(church.logoUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    church.churchName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (church.pastorName.isNotEmpty)
                    Text(
                      'Pastor: ${church.pastorName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (!isLoadingStats)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$likesCount',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Me gusta'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$membersCount',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Miembros'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          title: likedByMe ? 'Te gusta' : 'Me gusta',
                          icon: likedByMe
                              ? Icons.favorite
                              : Icons.favorite_border,
                          onTap: _toggleLike,
                          backgroundColor:
                          likedByMe ? Colors.red : const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionButton(
                          title: memberByMe ? 'Soy miembro' : 'Unirme',
                          icon: memberByMe
                              ? Icons.verified_user
                              : Icons.group_add_outlined,
                          onTap: _toggleMember,
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if ((church.spiritualHelpUrl ?? '').isNotEmpty ||
                      church.whatsapp.isNotEmpty)
                    _actionButton(
                      title: (church.spiritualHelpLabel ?? '').isNotEmpty
                          ? church.spiritualHelpLabel!
                          : 'Recibir apoyo espiritual',
                      icon: Icons.volunteer_activism_outlined,
                      onTap: () {
                        if ((church.spiritualHelpUrl ?? '').isNotEmpty) {
                          _openUrl(church.spiritualHelpUrl!);
                        } else {
                          _openWhatsApp(church.whatsapp);
                        }
                      },
                      backgroundColor: const Color(0xFF8E24AA),
                      foregroundColor: Colors.white,
                    ),
                  const SizedBox(height: 18),
                  _sectionCard(
                    title: 'Contacto',
                    icon: Icons.contact_phone_outlined,
                    child: Column(
                      children: [
                        _infoRow('Dirección', church.address),
                        _infoRow('Teléfono', church.phone),
                        _infoRow('WhatsApp', church.whatsapp),
                        _infoRow('Correo', church.email),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Ofrendar',
                    icon: Icons.volunteer_activism,
                    child: Column(
                      children: [
                        _infoRow('País', church.country),
                        _infoRow('Titular', church.donationAccountName),
                        _infoRow('Banco', church.donationBankName),
                        _infoRow('Cuenta', church.donationAccountNumber),
                        _infoRow('Tipo', church.donationAccountType),
                        _infoRow('Instrucciones', church.donationInstructions),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Horarios de culto',
                    icon: Icons.schedule_outlined,
                    child: isLoadingSchedules
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                        : _buildSchedules(),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Explorar esta iglesia',
                    icon: Icons.explore_outlined,
                    child: Column(
                      children: [
                        _actionButton(
                          title: 'Ver publicaciones y videos',
                          icon: Icons.dynamic_feed_outlined,
                          onTap: _openChurchFeed,
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        _actionButton(
                          title: 'Ver eventos',
                          icon: Icons.event_outlined,
                          onTap: _openChurchEvents,
                          backgroundColor: const Color(0xFFEF6C00),
                          foregroundColor: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        _actionButton(
                          title: 'Ver ubicación',
                          icon: Icons.location_on_outlined,
                          onTap: _openChurchLocation,
                          backgroundColor: const Color(0xFF455A64),
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}