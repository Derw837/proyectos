import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_profile_videos_service.dart';
import 'package:red_cristiana/features/media/presentation/screens/app_video_player_screen.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';

class ChurchProfileVideosManageScreen extends StatefulWidget {
  const ChurchProfileVideosManageScreen({super.key});

  @override
  State<ChurchProfileVideosManageScreen> createState() =>
      _ChurchProfileVideosManageScreenState();
}

class _ChurchProfileVideosManageScreenState
    extends State<ChurchProfileVideosManageScreen> {
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
        SnackBar(content: Text('Error cargando videos: $e')),
      );
    }
  }

  Future<void> _openCreateDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo video'),
              content: SizedBox(
                width: 430,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Ingresa el título' : null,
                          decoration: InputDecoration(
                            labelText: 'Título',
                            prefixIcon: const Icon(Icons.title),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            prefixIcon: const Icon(Icons.description_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: urlController,
                          validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Pega el enlace del video' : null,
                          decoration: InputDecoration(
                            labelText: 'Enlace del video',
                            prefixIcon: const Icon(Icons.link),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Puedes pegar enlaces de YouTube como:\n'
                                'https://www.youtube.com/watch?v=...\n'
                                'o\n'
                                'https://youtu.be/...\n\n'
                                'Si usas otro servidor, pega el enlace directo del video.',
                            style: TextStyle(height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;

                    try {
                      setDialogState(() {
                        saving = true;
                      });

                      final church = await ChurchProfileVideosService.getMyChurch();
                      if (church == null) {
                        throw Exception('No se encontró la iglesia');
                      }

                      final url = urlController.text.trim();
                      final thumbnail = ChurchProfileVideosService
                          .buildThumbnailFromYoutubeUrl(url);

                      await ChurchProfileVideosService.createVideo(
                        churchId: church['id'].toString(),
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        videoUrl: url,
                        thumbnailUrl: thumbnail,
                      );

                      if (!mounted) return;
                      Navigator.pop(dialogContext);
                      await _loadVideos();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Video publicado correctamente'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      setDialogState(() {
                        saving = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error publicando video: $e')),
                      );
                    }
                  },
                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Publicar'),
                ),
              ],
            );
          },
        );
      },
    );
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
        SnackBar(content: Text('Error eliminando video: $e')),
      );
    }
  }

  Widget _videoCard(Map<String, dynamic> video) {
    final title = video['title']?.toString() ?? '';
    final description = video['description']?.toString() ?? '';
    final thumbnailUrl = video['thumbnail_url']?.toString() ?? '';

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
          InkWell(
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
            child: thumbnailUrl.isNotEmpty
                ? Image.network(
              thumbnailUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            )
                : Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey.shade300,
              child: const Icon(Icons.ondemand_video, size: 60),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.4),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteVideo(video['id'].toString()),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChurchHeaderShell(
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
        title: const Text('Videos de mi iglesia'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : videos.isEmpty
          ? const Center(
        child: Text('Aún no has publicado videos.'),
      )
          : RefreshIndicator(
        onRefresh: _loadVideos,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: videos.length,
          itemBuilder: (context, index) => _videoCard(videos[index]),
        ),
      ),
        ),
    );
  }
}