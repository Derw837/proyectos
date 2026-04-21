import 'package:flutter/material.dart';
import 'package:red_cristiana/core/utils/app_error_helper.dart';
import 'package:flutter/services.dart';
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
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF152033);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE6EDF6);

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
        SnackBar(content: Text(await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudo actualizar el Me gusta en este momento.'))),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cambiar'),
              ),
            ],
          ),
        );

        if (!mounted) return;
        if (confirm != true) return;

        await client.from('church_memberships').delete().eq('user_id', user.id);

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
        SnackBar(content: Text(await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudo completar la membresía en este momento.'))),
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

  Future<void> _copyText(String label, String value) async {
    if (value.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: value.trim()));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copiado')),
    );
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
    final parts = [
      if (widget.church.country.trim().isNotEmpty) widget.church.country.trim(),
      if (widget.church.city.trim().isNotEmpty) widget.church.city.trim(),
      if (widget.church.address.trim().isNotEmpty) widget.church.address.trim(),
    ];

    final fullAddress = parts.join(', ');

    if (fullAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta iglesia no tiene ubicación registrada'),
        ),
      );
      return;
    }

    final encoded = Uri.encodeComponent(fullAddress);
    _openUrl('https://www.google.com/maps/search/?api=1&query=$encoded');
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
              fontSize: 12.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _primary, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: const TextStyle(
                      color: _textSoft,
                      fontSize: 12.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
    Color foregroundColor = Colors.white,
  }) {
    return Expanded(
      child: SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.4,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _primary, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w800,
              fontSize: 14.8,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
    IconData? icon,
    bool copyable = false,
  }) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: _textSoft),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w800,
                fontSize: 13.1,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _textSoft,
                fontSize: 13.2,
                height: 1.4,
              ),
            ),
          ),
          if (copyable)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _copyText(label, value),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: _primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage({
    required String? networkUrl,
    required IconData fallbackIcon,
  }) {
    if (networkUrl != null && networkUrl.trim().isNotEmpty) {
      return Image.network(
        networkUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _emptyHeaderImage(fallbackIcon),
      );
    }

    return _emptyHeaderImage(fallbackIcon);
  }

  Widget _emptyHeaderImage(IconData icon) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 42,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _buildLogoAvatar() {
    final church = widget.church;

    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white,
          width: 2.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: church.logoUrl != null && church.logoUrl!.trim().isNotEmpty
            ? Image.network(
          church.logoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: const Color(0xFFEAF2FF),
              child: const Center(
                child: Icon(
                  Icons.church,
                  color: _primary,
                  size: 36,
                ),
              ),
            );
          },
        )
            : Container(
          color: const Color(0xFFEAF2FF),
          child: const Center(
            child: Icon(
              Icons.church,
              color: _primary,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchedules() {
    if (isLoadingSchedules) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (schedules.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: const Text(
          'No hay horarios registrados.',
          style: TextStyle(
            color: _textSoft,
            fontSize: 13.2,
          ),
        ),
      );
    }

    return Column(
      children: schedules.map((schedule) {
        final day = schedule['day_name']?.toString() ?? '';
        final name = schedule['service_name']?.toString() ?? '';
        final start = schedule['start_time']?.toString() ?? '';
        final end = schedule['end_time']?.toString() ?? '';

        final scheduleText = end.isNotEmpty ? '$start - $end' : start;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.access_time_outlined,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (name.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          color: _textSoft,
                          fontSize: 13.2,
                        ),
                      ),
                    ],
                    if (scheduleText.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        scheduleText,
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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

  Widget _exploreButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 21),
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
                      fontSize: 14.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _textSoft,
                      fontSize: 12.6,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: _textSoft,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final church = widget.church;

    final location = [
      if (church.city.isNotEmpty) church.city,
      if (church.country.isNotEmpty) church.country,
    ].join(', ');

    final supportText = (church.spiritualHelpLabel ?? '').trim().isNotEmpty
        ? church.spiritualHelpLabel!.trim()
        : 'Recibir apoyo espiritual';

    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor: _primary,
            stretch: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  _buildHeaderImage(
                    networkUrl: church.coverUrl,
                    fallbackIcon: Icons.landscape_outlined,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.50),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: -34,
                    child: _buildLogoAvatar(),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 58, 16, 16),
                        child: Container(
                          width: double.infinity,
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
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                church.churchName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              if (church.pastorName.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Pastor: ${church.pastorName}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (location.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  location,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13.2,
                                  ),
                                ),
                              ],
                              if (church.description.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  church.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13.2,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (church.sector.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _heroChip(
                                      icon: Icons.place_outlined,
                                      text: church.sector,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!isLoadingStats)
                      Row(
                        children: [
                          _statCard(
                            value: '$likesCount',
                            label: 'Me gusta',
                            icon: Icons.favorite_outline,
                          ),
                          const SizedBox(width: 10),
                          _statCard(
                            value: '$membersCount',
                            label: 'Miembros',
                            icon: Icons.groups_outlined,
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _mainActionButton(
                          title: likedByMe ? 'Te gusta' : 'Me gusta',
                          icon: likedByMe
                              ? Icons.favorite
                              : Icons.favorite_border,
                          onTap: _toggleLike,
                          backgroundColor: likedByMe ? Colors.red : _primary,
                        ),
                        const SizedBox(width: 10),
                        _mainActionButton(
                          title: memberByMe ? 'Soy miembro' : 'Unirme',
                          icon: memberByMe
                              ? Icons.verified_user
                              : Icons.group_add_outlined,
                          onTap: _toggleMember,
                          backgroundColor: const Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                    if (church.whatsapp.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _openWhatsApp(church.whatsapp),
                          icon: const Icon(Icons.volunteer_activism_outlined),
                          label: Text(
                            supportText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.8,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8E24AA),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _sectionCard(
                      title: 'Contacto',
                      icon: Icons.contact_phone_outlined,
                      child: Column(
                        children: [
                          _infoRow(
                            label: 'Dirección',
                            value: church.address,
                            icon: Icons.location_on_outlined,
                            copyable: true,
                          ),
                          _infoRow(
                            label: 'Teléfono',
                            value: church.phone,
                            icon: Icons.phone_outlined,
                            copyable: true,
                          ),
                          _infoRow(
                            label: 'WhatsApp',
                            value: church.whatsapp,
                            icon: Icons.message_outlined,
                            copyable: true,
                          ),
                          _infoRow(
                            label: 'Correo',
                            value: church.email,
                            icon: Icons.email_outlined,
                            copyable: true,
                          ),
                        ],
                      ),
                    ),
                    _sectionCard(
                      title: 'Ofrendar',
                      icon: Icons.volunteer_activism_outlined,
                      child: Column(
                        children: [
                          _infoRow(
                            label: 'País',
                            value: church.country,
                            icon: Icons.public,
                          ),
                          _infoRow(
                            label: 'Titular',
                            value: church.donationAccountName,
                            icon: Icons.badge_outlined,
                          ),
                          _infoRow(
                            label: 'Banco',
                            value: church.donationBankName,
                            icon: Icons.account_balance_outlined,
                          ),
                          _infoRow(
                            label: 'Cuenta',
                            value: church.donationAccountNumber,
                            icon: Icons.numbers,
                          ),
                          _infoRow(
                            label: 'Tipo',
                            value: church.donationAccountType,
                            icon: Icons.credit_card_outlined,
                          ),
                          _infoRow(
                            label: 'Instrucciones',
                            value: church.donationInstructions,
                            icon: Icons.info_outline,
                          ),
                        ],
                      ),
                    ),
                    _sectionCard(
                      title: 'Horarios de culto',
                      icon: Icons.schedule_outlined,
                      child: _buildSchedules(),
                    ),
                    _sectionCard(
                      title: 'Explorar esta iglesia',
                      icon: Icons.explore_outlined,
                      child: Column(
                        children: [
                          _exploreButton(
                            title: 'Ver publicaciones y videos',
                            subtitle: 'Explora el contenido visual y el feed.',
                            icon: Icons.dynamic_feed_outlined,
                            onTap: _openChurchFeed,
                            color: _primary,
                          ),
                          const SizedBox(height: 10),
                          _exploreButton(
                            title: 'Ver eventos',
                            subtitle: 'Consulta actividades y reuniones.',
                            icon: Icons.event_outlined,
                            onTap: _openChurchEvents,
                            color: const Color(0xFFEF6C00),
                          ),
                          const SizedBox(height: 10),
                          _exploreButton(
                            title: 'Ver ubicación',
                            subtitle: 'Abrir esta iglesia en Google Maps.',
                            icon: Icons.location_on_outlined,
                            onTap: _openChurchLocation,
                            color: const Color(0xFF455A64),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}