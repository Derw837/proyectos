import 'package:flutter/material.dart';
import 'package:red_cristiana/features/media/data/media_video_service.dart';
import 'package:red_cristiana/features/media/presentation/screens/app_video_player_screen.dart';

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

  Widget _categoryChip(String value, String label) {
    final isSelected = selectedCategory == value;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _filterByCategory(value),
      ),
    );
  }

  Widget _videoCard(Map<String, dynamic> video) {
    final title = video['title']?.toString() ?? '';
    final description = video['description']?.toString() ?? '';
    final category = video['category']?.toString() ?? 'otro';
    final thumbnailUrl = video['thumbnail_url']?.toString() ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(22),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _categoryLabel(category),
                      style: const TextStyle(
                        color: Color(0xFF0D47A1),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
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
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        children: [
          const SizedBox(height: 10),
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
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredVideos.isEmpty
                ? const Center(
              child: Text('No hay videos disponibles todavía.'),
            )
                : RefreshIndicator(
              onRefresh: _loadVideos,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
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