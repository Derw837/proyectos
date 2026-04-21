import 'package:flutter/material.dart';
import 'package:red_cristiana/features/media/data/media_video_service.dart';
import 'package:red_cristiana/features_tv/videos/tv_series_detail_screen.dart';
import 'package:red_cristiana/features_tv/videos/tv_video_detail_screen.dart';
import 'package:red_cristiana/features_tv/widgets/tv_hero_banner.dart';
import 'package:red_cristiana/features_tv/widgets/tv_poster_card.dart';
import 'package:red_cristiana/features_tv/widgets/tv_section_row.dart';

class TvVideosScreen extends StatefulWidget {
  const TvVideosScreen({super.key});

  @override
  State<TvVideosScreen> createState() => _TvVideosScreenState();
}

class _TvVideosScreenState extends State<TvVideosScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = MediaVideoService.getMediaHome();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final media = snapshot.data!;

        final featuredMovies =
        List<Map<String, dynamic>>.from(media['featuredMovies'] ?? []);
        final featuredSeries =
        List<Map<String, dynamic>>.from(media['featuredSeries'] ?? []);
        final featuredPreachings =
        List<Map<String, dynamic>>.from(media['featuredPreachings'] ?? []);
        final featuredTestimonies =
        List<Map<String, dynamic>>.from(media['featuredTestimonies'] ?? []);
        final continueWatchingSeries =
        List<Map<String, dynamic>>.from(media['continueWatchingSeries'] ?? []);

        final heroItem = featuredMovies.isNotEmpty
            ? featuredMovies.first
            : featuredSeries.isNotEmpty
            ? featuredSeries.first
            : featuredPreachings.isNotEmpty
            ? featuredPreachings.first
            : featuredTestimonies.isNotEmpty
            ? featuredTestimonies.first
            : null;

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = MediaVideoService.getMediaHome();
              });
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 30),
              children: [
                const Text(
                  'Biblioteca de video',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explora películas, series, predicaciones y testimonios en una experiencia pensada para pantalla grande.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 18),
                TvHeroBanner(
                  title: heroItem?['title']?.toString() ?? 'Red Cristiana TV',
                  description: heroItem?['description']?.toString().trim().isNotEmpty == true
                      ? heroItem!['description'].toString()
                      : 'Descubre contenido cristiano cuidadosamente organizado para disfrutarlo con una interfaz premium en tu TV.',
                  imageUrl: heroItem?['thumbnail_url']?.toString() ??
                      heroItem?['cover_url']?.toString(),
                  category: _prettyCategory(heroItem?['category']?.toString()),
                ),
                if (featuredMovies.isNotEmpty)
                  TvSectionRow(
                    title: 'Películas',
                    subtitle: 'Selección destacada para disfrutar en familia',
                    children: featuredMovies.map((item) {
                      return TvPosterCard(
                        title: item['title']?.toString() ?? 'Película',
                        subtitle: 'Película',
                        imageUrl: item['thumbnail_url']?.toString(),
                        onTap: () => _openVideoDetail(item),
                      );
                    }).toList(),
                  ),
                if (featuredSeries.isNotEmpty)
                  TvSectionRow(
                    title: 'Series',
                    subtitle: 'Historias y capítulos para seguir viendo',
                    children: featuredSeries.map((item) {
                      return TvPosterCard(
                        title: item['title']?.toString() ?? 'Serie',
                        subtitle: 'Serie',
                        imageUrl: item['thumbnail_url']?.toString() ??
                            item['cover_url']?.toString(),
                        onTap: () => _openSeriesDetail(item),
                      );
                    }).toList(),
                  ),
                if (featuredPreachings.isNotEmpty)
                  TvSectionRow(
                    title: 'Predicaciones',
                    subtitle: 'Mensajes seleccionados para fortalecer tu fe',
                    children: featuredPreachings.map((item) {
                      return TvPosterCard(
                        title: item['title']?.toString() ?? 'Predicación',
                        subtitle: 'Predicación',
                        imageUrl: item['thumbnail_url']?.toString(),
                        onTap: () => _openVideoDetail(item),
                      );
                    }).toList(),
                  ),
                if (featuredTestimonies.isNotEmpty)
                  TvSectionRow(
                    title: 'Testimonios',
                    subtitle: 'Historias reales que inspiran y edifican',
                    children: featuredTestimonies.map((item) {
                      return TvPosterCard(
                        title: item['title']?.toString() ?? 'Testimonio',
                        subtitle: 'Testimonio',
                        imageUrl: item['thumbnail_url']?.toString(),
                        onTap: () => _openVideoDetail(item),
                      );
                    }).toList(),
                  ),
                if (continueWatchingSeries.isNotEmpty)
                  TvSectionRow(
                    title: 'Continúa viendo',
                    subtitle: 'Retoma tu progreso desde donde quedaste',
                    children: continueWatchingSeries.map((entry) {
                      final series =
                      Map<String, dynamic>.from(entry['series'] ?? {});
                      final episode =
                      Map<String, dynamic>.from(entry['episode'] ?? {});

                      return TvPosterCard(
                        title: series['title']?.toString() ?? 'Serie',
                        subtitle: 'Episodio: ${episode['title']?.toString() ?? ''}',
                        imageUrl: series['thumbnail_url']?.toString() ??
                            series['cover_url']?.toString(),
                        onTap: () => _openSeriesDetail(series),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openVideoDetail(Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TvVideoDetailScreen(item: item),
      ),
    );
  }

  void _openSeriesDetail(Map<String, dynamic> series) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TvSeriesDetailScreen(series: series),
      ),
    );
  }

  String? _prettyCategory(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'pelicula':
        return 'Película';
      case 'predicacion':
        return 'Predicación';
      case 'testimonio':
        return 'Testimonio';
      case 'serie':
        return 'Serie';
      default:
        return raw;
    }
  }
}