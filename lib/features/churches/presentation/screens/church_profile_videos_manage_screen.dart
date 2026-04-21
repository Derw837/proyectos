import 'package:flutter/material.dart';
import 'package:red_cristiana/core/utils/app_error_helper.dart';
import 'package:red_cristiana/features/churches/data/church_profile_videos_service.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';
import 'package:red_cristiana/features/media/presentation/screens/app_video_player_screen.dart';

class ChurchProfileVideosManageScreen extends StatefulWidget {
  const ChurchProfileVideosManageScreen({super.key});

  @override
  State<ChurchProfileVideosManageScreen> createState() =>
      _ChurchProfileVideosManageScreenState();
}

class _ChurchProfileVideosManageScreenState
    extends State<ChurchProfileVideosManageScreen> {
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF152033);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE6EDF6);

  bool isLoading = true;
  List<Map<String, dynamic>> videos = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final data = await ChurchProfileVideosService.getMyVideos();

      if (!mounted) return;
      setState(() {
        videos = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudieron cargar los videos en este momento.'))),
      );
    }
  }

  String _formatDateForDisplay(String date) {
    if (date.trim().isEmpty) return 'Sin fecha';

    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;

    const months = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];

    return '${parsed.day} ${months[parsed.month]} ${parsed.year}';
  }

  Future<void> _openCreateSheet() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();

    final formKey = GlobalKey<FormState>();
    bool saving = false;
    String previewThumbnail = '';

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updatePreview() {
              final url = urlController.text.trim();
              final thumb =
              ChurchProfileVideosService.buildThumbnailFromYoutubeUrl(url);

              setSheetState(() {
                previewThumbnail = thumb ?? '';
              });
            }

            InputDecoration decoration(String label, IconData icon) {
              return InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  color: _textSoft,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Icon(icon, color: _primary, size: 21),
                filled: true,
                fillColor: const Color(0xFFF9FBFE),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _primary, width: 1.3),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Colors.red, width: 1.2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _border),
                ),
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                  ),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 52,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCAD5E5),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primary, _primaryLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Nuevo video',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Publica videos de predicaciones, actividades, transmisiones grabadas o contenido de tu iglesia.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13.2,
                                    height: 1.35,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _TopChip(
                                      icon: Icons.ondemand_video_outlined,
                                      text: 'YouTube o enlace directo',
                                    ),
                                    _TopChip(
                                      icon: Icons.image_outlined,
                                      text: 'Miniatura automática',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Información principal',
                            style: TextStyle(
                              color: _textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: titleController,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Ingresa el título'
                                : null,
                            decoration: decoration(
                              'Título del video',
                              Icons.title_outlined,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 4,
                            decoration: decoration(
                              'Descripción',
                              Icons.description_outlined,
                            ).copyWith(
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Enlace del video',
                            style: TextStyle(
                              color: _textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: urlController,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Pega el enlace del video'
                                : null,
                            onChanged: (_) => updatePreview(),
                            decoration: decoration(
                              'https://...',
                              Icons.link_outlined,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(
                              'Puedes pegar enlaces de YouTube como:\n'
                                  'https://www.youtube.com/watch?v=...\n'
                                  'https://youtu.be/...\n\n'
                                  'También puedes usar enlaces directos si tu reproductor los soporta.',
                              style: TextStyle(
                                color: _textDark,
                                height: 1.45,
                                fontSize: 12.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Vista previa',
                            style: TextStyle(
                              color: _textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 190,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: _border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: previewThumbnail.isNotEmpty
                                ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  previewThumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return _videoPlaceholder();
                                  },
                                ),
                                Container(
                                  color: Colors.black.withValues(alpha: 0.22),
                                ),
                                const Center(
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.play_arrow_rounded,
                                      color: _primary,
                                      size: 34,
                                    ),
                                  ),
                                ),
                              ],
                            )
                                : _videoPlaceholder(),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: saving
                                      ? null
                                      : () => Navigator.pop(sheetContext),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _primary,
                                    side: const BorderSide(color: _border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: saving
                                      ? null
                                      : () async {
                                    if (!formKey.currentState!
                                        .validate()) {
                                      return;
                                    }

                                    try {
                                      setSheetState(() {
                                        saving = true;
                                      });

                                      final church =
                                      await ChurchProfileVideosService
                                          .getMyChurch();
                                      if (church == null) {
                                        throw Exception(
                                          'No se encontró la iglesia',
                                        );
                                      }

                                      final url = urlController.text.trim();
                                      final thumbnail =
                                          ChurchProfileVideosService
                                              .buildThumbnailFromYoutubeUrl(
                                            url,
                                          ) ??
                                              '';

                                      await ChurchProfileVideosService
                                          .createVideo(
                                        churchId:
                                        church['id'].toString(),
                                        title:
                                        titleController.text.trim(),
                                        description: descriptionController
                                            .text
                                            .trim(),
                                        videoUrl: url,
                                        thumbnailUrl: thumbnail,
                                      );

                                      if (!mounted) return;
                                      Navigator.pop(sheetContext, true);

                                    } catch (e) {
                                      if (!mounted) return;
                                      setSheetState(() {
                                        saving = false;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudo publicar el video en este momento.'),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: saving
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.1,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Icon(Icons.publish_outlined),
                                  label: Text(
                                    saving ? 'Publicando...' : 'Publicar',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                    const Color(0xFFB8C7E0),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (created == true) {
      await _loadVideos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video publicado correctamente'),
        ),
      );
    }

    titleController.dispose();
    descriptionController.dispose();
    urlController.dispose();
  }

  Future<void> _deleteVideo(String videoId) async {
    try {
      await ChurchProfileVideosService.deleteVideo(videoId);
      await _loadVideos();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video eliminado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudo eliminar el video en este momento.'))),
      );
    }
  }

  Future<void> _confirmDelete(String videoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Eliminar video'),
          content: const Text(
            '¿Seguro que deseas eliminar este video?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteVideo(videoId);
    }
  }

  void _openVideoPlayer(Map<String, dynamic> video) {
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
          const Text(
            'Videos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TopChip(
                icon: Icons.ondemand_video_outlined,
                text: '${videos.length} total',
              ),
              const _TopChip(
                icon: Icons.play_circle_outline,
                text: 'Contenido audiovisual',
              ),
              const _TopChip(
                icon: Icons.auto_awesome_outlined,
                text: 'Biblioteca visual',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.video_library_outlined,
              color: _primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              videos.isEmpty
                  ? 'Todavía no hay videos publicados.'
                  : (videos.length == 1
                  ? 'Tienes 1 video publicado.'
                  : 'Tienes ${videos.length} videos publicados.'),
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoCard(Map<String, dynamic> video) {
    final title = video['title']?.toString().trim() ?? '';
    final description = video['description']?.toString().trim() ?? '';
    final thumbnailUrl = video['thumbnail_url']?.toString().trim() ?? '';
    final createdAt = video['created_at']?.toString().trim() ?? '';
    final videoId = video['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openVideoPlayer(video),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: thumbnailUrl.isNotEmpty
                      ? Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _videoPlaceholder();
                    },
                  )
                      : _videoPlaceholder(),
                ),
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.black.withValues(alpha: 0.18),
                ),
                const Positioned.fill(
                  child: Center(
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: _primary,
                        size: 34,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: videoId.isEmpty ? null : () => _confirmDelete(videoId),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (createdAt.isNotEmpty)
                      _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        text: _formatDateForDisplay(createdAt),
                        bgColor: const Color(0xFFEAF2FF),
                        textColor: _primary,
                      ),
                    const _InfoChip(
                      icon: Icons.visibility_outlined,
                      text: 'Disponible',
                      bgColor: Color(0xFFE8F5E9),
                      textColor: Color(0xFF2E7D32),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title.isEmpty ? 'Video sin título' : title,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textSoft,
                      fontSize: 13.4,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => _openVideoPlayer(video),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text(
                      'Ver video',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _videoPlaceholder() {
    return Container(
      color: const Color(0xFFEAF2FF),
      child: const Center(
        child: Icon(
          Icons.ondemand_video_outlined,
          color: _primary,
          size: 48,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.video_library_outlined,
              size: 38,
              color: _primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Todavía no has publicado videos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Agrega predicaciones, enseñanzas, eventos grabados o contenido audiovisual para tu comunidad.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSoft,
              fontSize: 13.2,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _openCreateSheet,
              icon: const Icon(Icons.add),
              label: const Text(
                'Publicar primer video',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _content() {
    return RefreshIndicator(
      onRefresh: _loadVideos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _heroCard(),
          const SizedBox(height: 18),
          _sectionTitle(
            'Resumen',
            'Gestiona los videos publicados por tu iglesia.',
          ),
          _summaryCard(),
          const SizedBox(height: 20),
          _sectionTitle(
            'Listado de videos',
            'Aquí aparecen todos los videos publicados.',
          ),
          if (videos.isEmpty) _emptyState() else ...videos.map(_videoCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChurchHeaderShell(
      child: Scaffold(
        backgroundColor: _surface,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreateSheet,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add),
          label: const Text(
            'Nuevo video',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _content(),
      ),
    );
  }
}

class _TopChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TopChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bgColor;
  final Color textColor;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 11.8,
            ),
          ),
        ],
      ),
    );
  }
}