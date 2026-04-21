import 'package:flutter/material.dart';
import 'package:red_cristiana/features/live_tv/data/live_tv_service.dart';
import 'package:red_cristiana/features/media/data/media_video_service.dart';
import 'package:red_cristiana/features/radios/data/radio_service.dart';
import 'package:red_cristiana/features_tv/widgets/tv_hero_banner.dart';
import 'package:red_cristiana/features_tv/widgets/tv_poster_card.dart';
import 'package:red_cristiana/features_tv/widgets/tv_section_row.dart';

class TvHomeScreen extends StatefulWidget {
  const TvHomeScreen({super.key});

  @override
  State<TvHomeScreen> createState() => _TvHomeScreenState();
}

class _TvHomeScreenState extends State<TvHomeScreen> {
  late Future<_TvHomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TvHomeData> _load() async {
    final media = await MediaVideoService.getMediaHome();
    final radios = await RadioService.getActiveRadios();
    final channels = await LiveTvService.getActiveChannels();

    return _TvHomeData(
      media: media,
      radios: radios,
      channels: channels,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TvHomeData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final data = snapshot.data!;
        final media = data.media;

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
                _future = _load();
              });
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 30),
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bienvenido a una experiencia pensada para la sala',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TvHeroBanner(
                  title: heroItem?['title']?.toString() ?? 'Red Cristiana TV',
                  description: heroItem?['description']?.toString().trim().isNotEmpty == true
                      ? heroItem!['description'].toString()
                      : 'Películas, series, predicaciones, radios y canales cristianos en una interfaz pensada para pantalla grande.',
                  imageUrl: heroItem?['thumbnail_url']?.toString() ??
                      heroItem?['cover_url']?.toString(),
                  category: _prettyCategory(heroItem?['category']?.toString()),
                ),
                if (continueWatchingSeries.isNotEmpty)
                  TvSectionRow(
                    title: 'Continúa viendo',
                    subtitle: 'Retoma exactamente donde te quedaste',
                    children: continueWatchingSeries.map((entry) {
                      final series =
                      Map<String, dynamic>.from(entry['series'] ?? {});
                      final episode =
                      Map<String, dynamic>.from(entry['episode'] ?? {});

                      return TvPosterCard(
                        title: series['title']?.toString() ?? 'Serie',
                        subtitle:
                        'Episodio: ${episode['title']?.toString() ?? ''}',
                        imageUrl: series['thumbnail_url']?.toString() ??
                            series['cover_url']?.toString(),
                      );
                    }).toList(),
                  ),
                if (featuredMovies.isNotEmpty)
                  TvSectionRow(
                    title: 'Películas destacadas',
                    subtitle: 'Contenido seleccionado para una noche inolvidable',
                    children: featuredMovies.map((item) {
                      return TvPosterCard(
                        title: item['title']?.toString() ?? 'Película',
                        subtitle: 'Película',
                        imageUrl: item['thumbnail_url']?.toString(),
                      );
                    }).toList(),
                  ),
                if (featuredSeries.isNotEmpty)
                  TvSectionRow(
                    title: 'Series',
                    subtitle: 'Historias para seguir episodio tras episodio',
                    children: featuredSeries.map((item) {
                      return TvPosterCard(
                        title: item['title']?.toString() ?? 'Serie',
                        subtitle: 'Serie',
                        imageUrl: item['thumbnail_url']?.toString() ??
                            item['cover_url']?.toString(),
                      );
                    }).toList(),
                  ),
                if (featuredPreachings.isNotEmpty)
                  TvSectionRow(
                    title: 'Predicaciones',
                    subtitle: 'Mensajes para fortalecer la fe',
                    children: featuredPreachings.map((item) {
                      return TvPosterCard(
                        title: item['title']?.toString() ?? 'Predicación',
                        subtitle: 'Predicación',
                        imageUrl: item['thumbnail_url']?.toString(),
                      );
                    }).toList(),
                  ),
                if (featuredTestimonies.isNotEmpty)
                  TvSectionRow(
                    title: 'Testimonios',
                    subtitle: 'Historias reales que inspiran',
                    children: featuredTestimonies.map((item) {
                      return TvPosterCard(
                        title: item['title']?.toString() ?? 'Testimonio',
                        subtitle: 'Testimonio',
                        imageUrl: item['thumbnail_url']?.toString(),
                      );
                    }).toList(),
                  ),
                if (data.radios.isNotEmpty)
                  TvSectionRow(
                    title: 'Radios cristianas',
                    subtitle: 'Escucha emisoras activas en este momento',
                    children: data.radios.take(12).map((item) {
                      return TvPosterCard(
                        title: item['name']?.toString() ?? 'Radio',
                        subtitle: item['country']?.toString() ??
                            item['city']?.toString() ??
                            'En vivo',
                        imageUrl: item['logo_url']?.toString(),
                      );
                    }).toList(),
                  ),
                if (data.channels.isNotEmpty)
                  TvSectionRow(
                    title: 'Canales en vivo',
                    subtitle: 'Transmisiones activas para ver en pantalla grande',
                    children: data.channels.take(12).map((item) {
                      return TvPosterCard(
                        title: item['name']?.toString() ?? 'Canal',
                        subtitle: item['country']?.toString() ??
                            item['category']?.toString() ??
                            'TV en vivo',
                        imageUrl: item['thumbnail_url']?.toString() ??
                            item['logo_url']?.toString(),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
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

class _TvHomeData {
  final Map<String, dynamic> media;
  final List<Map<String, dynamic>> radios;
  final List<Map<String, dynamic>> channels;

  _TvHomeData({
    required this.media,
    required this.radios,
    required this.channels,
  });
}