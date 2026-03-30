import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_posts_service.dart';
import 'package:red_cristiana/features/churches/data/church_profile_videos_service.dart';
import 'package:red_cristiana/features/churches/data/church_public_service.dart';
import 'package:red_cristiana/features/churches/data/models/church_model.dart';
import 'package:red_cristiana/features/media/presentation/screens/app_video_player_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/post_images_widget.dart';
import 'package:red_cristiana/features/churches/presentation/screens/post_gallery_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_events_screen.dart';

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
  bool isLoadingPosts = true;
  bool isLoadingStats = true;
  bool isLoadingVideos = true;
  bool isLoadingEvents = true;

  List<Map<String, dynamic>> schedules = [];
  List<Map<String, dynamic>> posts = [];
  List<Map<String, dynamic>> videos = [];
  List<Map<String, dynamic>> events = [];

  int likesCount = 0;
  int membersCount = 0;
  bool likedByMe = false;
  bool memberByMe = false;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
    _loadPosts();
    _loadStats();
    _loadVideos();
    _loadEvents();
  }

  Future<void> _loadSchedules() async {
    try {
      final response = await Supabase.instance.client
          .from('church_schedules')
          .select()
          .eq('church_id', widget.church.id)
          .order('created_at');

      if (!mounted) return;

      setState(() {
        schedules = List<Map<String, dynamic>>.from(response);
        isLoadingSchedules = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoadingSchedules = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    try {
      final response = await ChurchPostsService.getChurchPosts(widget.church.id);

      if (!mounted) return;
      setState(() {
        posts = response;
        isLoadingPosts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoadingPosts = false;
      });
    }
  }

  Future<void> _loadVideos() async {
    try {
      final response =
      await ChurchProfileVideosService.getChurchVideos(widget.church.id);

      if (!mounted) return;
      setState(() {
        videos = response;
        isLoadingVideos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoadingVideos = false;
      });
    }
  }

  Future<void> _loadEvents() async {
    try {
      final response = await Supabase.instance.client
          .from('church_events')
          .select()
          .eq('church_id', widget.church.id)
          .eq('status', 'published')
          .order('event_date', ascending: true);

      if (!mounted) return;

      setState(() {
        events = List<Map<String, dynamic>>.from(response);
        isLoadingEvents = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoadingEvents = false;
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

      // buscar membresía actual
      final current = await client
          .from('church_memberships')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (current != null) {
        final currentChurchId = current['church_id'].toString();

        // si ya es miembro de ESTA iglesia → salir
        if (currentChurchId == widget.church.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ya eres miembro de esta iglesia')),
          );
          return;
        }

        // preguntar si quiere cambiar
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Cambiar membresía'),
            content: const Text(
                'Ya eres miembro de otra iglesia.\n¿Quieres cambiar a esta?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cambiar'),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        // eliminar membresía anterior
        await client
            .from('church_memberships')
            .delete()
            .eq('user_id', user.id);
      }

      // crear nueva membresía
      await client.from('church_memberships').insert({
        'user_id': user.id,
        'church_id': widget.church.id,
      });

      await _loadStats();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ahora eres miembro de esta iglesia')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de membresía: $e')),
      );
    }
  }

  Future<void> _togglePostLike(String postId) async {
    try {
      await ChurchPostsService.togglePostLike(postId);
      await _loadPosts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en Me gusta: $e')),
      );
    }
  }

  Future<void> _toggleVideoLike(String videoId) async {
    try {
      await ChurchProfileVideosService.toggleVideoLike(videoId);
      await _loadVideos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en Me gusta: $e')),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    if (url.trim().isEmpty) return;

    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
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

  Widget _scheduleCard(Map<String, dynamic> item) {
    final day = item['day_name']?.toString() ?? '';
    final start = item['start_time']?.toString() ?? '';
    final end = item['end_time']?.toString() ?? '';
    final service = item['service_name']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.5,
            ),
          ),
          if (service.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(service),
          ],
          if (start.isNotEmpty || end.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '$start${end.isNotEmpty ? ' - $end' : ''}',
              style: const TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _postCard(Map<String, dynamic> post) {
    final title = post['title']?.toString() ?? '';
    final content = post['content']?.toString() ?? '';
    final likes = post['likes_count'] ?? 0;
    final liked = post['liked_by_me'] ?? false;
    final images = List<Map<String, dynamic>>.from(post['images'] ?? []);

    final urls = images
        .map((e) => e['image_url']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostImagesWidget(imageUrls: urls),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (title.isNotEmpty && content.isNotEmpty)
                  const SizedBox(height: 8),
                if (content.isNotEmpty)
                  Text(
                    content,
                    style: const TextStyle(
                      color: Colors.black87,
                      height: 1.45,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _togglePostLike(post['id'].toString()),
                      icon: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? Colors.red : Colors.black54,
                      ),
                    ),
                    Text('$likes Me gusta'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoCard(Map<String, dynamic> video) {
    final title = video['title']?.toString() ?? '';
    final description = video['description']?.toString() ?? '';
    final thumbnailUrl = video['thumbnail_url']?.toString() ?? '';
    final likes = video['likes_count'] ?? 0;
    final liked = video['liked_by_me'] == true;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppVideoPlayerScreen(
              title: video['title']?.toString() ?? '',
              description: video['description']?.toString() ?? '',
              videoUrl: video['video_url']?.toString() ?? '',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnailUrl.isNotEmpty)
              Image.network(
                thumbnailUrl,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 190,
                color: Colors.grey.shade300,
                child: const Icon(Icons.ondemand_video, size: 60),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.5,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _toggleVideoLike(video['id'].toString()),
                        icon: Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          color: liked ? Colors.red : Colors.black54,
                        ),
                      ),
                      Text('$likes Me gusta'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventCard(Map<String, dynamic> event) {
    final title = event['title']?.toString() ?? '';
    final description = event['description']?.toString() ?? '';
    final date = event['event_date']?.toString() ?? '';
    final start = event['start_time']?.toString() ?? '';
    final end = event['end_time']?.toString() ?? '';
    final address = event['address']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Fecha: $date'),
          ],
          if (start.isNotEmpty || end.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Hora: $start${end.isNotEmpty ? ' - $end' : ''}',
              style: const TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Lugar: $address'),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(height: 1.4),
            ),
          ],
        ],
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
                errorBuilder: (_, __, ___) => Container(
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
              padding: const EdgeInsets.all(20),
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
                      fontSize: 28,
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
                          icon: likedByMe ? Icons.favorite : Icons.favorite_border,
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
                        : schedules.isEmpty
                        ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('No hay horarios publicados.'),
                    )
                        : Column(
                      children: schedules.map(_scheduleCard).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Eventos',
                    icon: Icons.event_outlined,
                    child: isLoadingEvents
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                        : events.isEmpty
                        ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('No hay eventos publicados.'),
                    )
                        : Column(
                      children: [
                        ...events.take(3).map(_eventCard),
                        if (events.length > 3)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChurchEventsScreen(
                                      churchId: widget.church.id,
                                      churchName: widget.church.churchName,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Ver todos los eventos'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Publicaciones',
                    icon: Icons.photo_library_outlined,
                    child: isLoadingPosts
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                        : posts.isEmpty
                        ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('No hay publicaciones todavía.'),
                    )
                        : Column(
                      children: posts.map(_postCard).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Videos de la iglesia',
                    icon: Icons.ondemand_video_outlined,
                    child: isLoadingVideos
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                        : videos.isEmpty
                        ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('No hay videos publicados todavía.'),
                    )
                        : Column(
                      children: videos.map(_videoCard).toList(),
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