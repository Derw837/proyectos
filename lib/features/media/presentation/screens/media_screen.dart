import 'package:flutter/material.dart';
import 'package:red_cristiana/features/media/data/media_video_service.dart';
import 'package:red_cristiana/features/media/presentation/screens/app_video_player_screen.dart';
import 'package:red_cristiana/features/media/presentation/screens/network_video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> allVideos = [];
  List<Map<String, dynamic>> filteredVideos = [];
  String selectedCategory = 'todos';

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final data = await MediaVideoService.getActiveVideos();

      if (!mounted) return;
      setState(() {
        allVideos = data;
        filteredVideos = data;
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

  void _filterByCategory(String category) {
    setState(() {
      selectedCategory = category;

      if (category == 'todos') {
        filteredVideos = allVideos;
      } else {
        filteredVideos = allVideos
            .where((video) => video['category']?.toString() == category)
            .toList();
      }
    });
  }

  String _categoryLabel(String value) {
    switch (value) {
      case 'pelicula':
        return 'Películas';
      case 'serie':
        return 'Series';
      case 'predicacion':
        return 'Predicaciones';
      case 'testimonio':
        return 'Testimonios';
      default:
        return 'Otros';
    }
  }

  IconData _categoryIcon(String value) {
    switch (value) {
      case 'pelicula':
        return Icons.movie_outlined;
      case 'serie':
        return Icons.tv_outlined;
      case 'predicacion':
        return Icons.mic_none_outlined;
      case 'testimonio':
        return Icons.favorite_border;
      default:
        return Icons.ondemand_video_outlined;
    }
  }

  String _detectVideoType(String url) {
    final value = url.trim().toLowerCase();

    if (value.contains('youtube.com') || value.contains('youtu.be')) {
      return 'youtube';
    }

    if (value.contains('.m3u8')) {
      return 'm3u8';
    }

    if (value.contains('.mp4')) {
      return 'mp4';
    }

    return 'external';
  }

  String _sourceTypeLabel(String value) {
    switch (value) {
      case 'youtube':
        return 'YouTube';
      case 'm3u8':
        return 'Streaming';
      case 'mp4':
        return 'MP4';
      default:
        return 'Externo';
    }
  }

  Future<void> _openMediaVideo(Map<String, dynamic> video) async {
    final title = video['title']?.toString() ?? '';
    final description = video['description']?.toString() ?? '';
    final videoUrl = video['video_url']?.toString() ?? '';

    if (videoUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este video no tiene enlace disponible')),
      );
      return;
    }

    final sourceType = _detectVideoType(videoUrl);

    if (sourceType == 'youtube') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppVideoPlayerScreen(
            title: title,
            description: description,
            videoUrl: videoUrl,
          ),
        ),
      );
      return;
    }

    if (sourceType == 'mp4' || sourceType == 'm3u8') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NetworkVideoPlayerScreen(
            title: title,
            description: description,
            videoUrl: videoUrl,
          ),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(videoUrl);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El enlace del video no es válido')),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el video')),
      );
    }
  }

  Widget _categoryChip(String value, String label) {
    final isSelected = selectedCategory == value;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => _filterByCategory(value),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFDCEBFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF0D47A1)
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220D47A1),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.ondemand_video,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Películas, series y más',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Disfruta contenido cristiano en video desde un solo lugar.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
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
    final category = video['category']?.toString() ?? 'otro';
    final thumbnailUrl = video['thumbnail_url']?.toString() ?? '';
    final videoUrl = video['video_url']?.toString() ?? '';
    final sourceType = _detectVideoType(videoUrl);
    final isFeatured = video['is_featured'] == true;
    final country = video['country']?.toString().trim() ?? '';
    final city = video['city']?.toString().trim() ?? '';

    String actionText = 'Abrir video';
    if (sourceType == 'youtube') {
      actionText = 'Ver en la app';
    } else if (sourceType == 'mp4' || sourceType == 'm3u8') {
      actionText = 'Reproducir ahora';
    }

    final locationText = [
      if (country.isNotEmpty) country,
      if (city.isNotEmpty) city,
    ].join(' • ');

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _openMediaVideo(video),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (thumbnailUrl.isNotEmpty)
                  Image.network(
                    thumbnailUrl,
                    width: double.infinity,
                    height: 205,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 205,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.ondemand_video, size: 64),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 205,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.ondemand_video, size: 64),
                  ),

                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.14),
                          Colors.black.withOpacity(0.45),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _categoryIcon(category),
                              size: 14,
                              color: const Color(0xFF0D47A1),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _categoryLabel(category),
                              style: const TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Destacado',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.92),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F5F7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _sourceTypeLabel(sourceType),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      if (locationText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            locationText,
                            style: const TextStyle(
                              color: Color(0xFF0D47A1),
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D47A1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              actionText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.black45,
                      ),
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

  Widget _buildHeaderInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text(
            '${filteredVideos.length} contenido${filteredVideos.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          const Text(
            'Explora y reproduce',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
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
      body: Column(
        children: [
          _buildHeroSection(),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip('todos', 'Todos'),
                _categoryChip('pelicula', 'Películas'),
                _categoryChip('serie', 'Series'),
                _categoryChip('predicacion', 'Predicaciones'),
                _categoryChip('testimonio', 'Testimonios'),
                _categoryChip('otro', 'Otros'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildHeaderInfo(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredVideos.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay videos disponibles todavía.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadVideos,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                itemCount: filteredVideos.length,
                itemBuilder: (context, index) =>
                    _videoCard(filteredVideos[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}