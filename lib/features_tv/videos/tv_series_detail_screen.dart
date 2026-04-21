import 'package:flutter/material.dart';
import 'package:red_cristiana/features/media/data/media_video_service.dart';
import 'package:red_cristiana/features_tv/player/tv_series_episode_player_screen.dart';
import 'package:red_cristiana/features_tv/widgets/tv_poster_card.dart';

class TvSeriesDetailScreen extends StatefulWidget {
  final Map<String, dynamic> series;

  const TvSeriesDetailScreen({
    super.key,
    required this.series,
  });

  @override
  State<TvSeriesDetailScreen> createState() => _TvSeriesDetailScreenState();
}

class _TvSeriesDetailScreenState extends State<TvSeriesDetailScreen> {
  late Future<_SeriesData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SeriesData> _load() async {
    final seriesId = widget.series['id']?.toString() ?? '';

    final seriesData = await MediaVideoService.getSeriesById(seriesId);
    final episodes = await MediaVideoService.getSeriesEpisodes(seriesId);
    final progress = await MediaVideoService.getSeriesProgress(seriesId);

    return _SeriesData(
      series: seriesData ?? widget.series,
      episodes: episodes,
      progress: progress,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: FutureBuilder<_SeriesData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            final series = data.series;
            final episodes = data.episodes;
            final progress = data.progress;
            final grouped = _groupBySeason(episodes);

            final title = series['title']?.toString() ?? 'Serie';
            final description =
            (series['description']?.toString().trim().isNotEmpty ?? false)
                ? series['description'].toString()
                : 'Contenido disponible.';
            final image = series['cover_url']?.toString() ??
                series['thumbnail_url']?.toString();

            final progressEpisode = _findProgressEpisode(
              episodes: episodes,
              progress: progress,
            );

            final firstEpisode = episodes.isNotEmpty ? episodes.first : null;

            return ListView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 30),
              children: [
                Row(
                  children: [
                    _TvButton(
                      label: 'Volver',
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // HEADER
                Container(
                  height: 380,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0x22FFFFFF)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (image != null && image.isNotEmpty)
                        Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.black),
                        )
                      else
                        Container(color: Colors.black),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xC0000000),
                              Color(0x90000000),
                              Color(0xE0060A12),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Serie',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints:
                              const BoxConstraints(maxWidth: 760),
                              child: Text(
                                description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                if (progressEpisode != null)
                                  _TvButton(
                                    label:
                                    'Continuar · T${progressEpisode['season_number']} E${progressEpisode['episode_number']}',
                                    icon: Icons.play_circle_fill_rounded,
                                    filled: true,
                                    onTap: () => _openEpisode(
                                      series: series,
                                      episodes: episodes,
                                      episode: progressEpisode,
                                    ),
                                  )
                                else if (firstEpisode != null)
                                  _TvButton(
                                    label:
                                    'Ver desde el inicio · T${firstEpisode['season_number']} E${firstEpisode['episode_number']}',
                                    icon: Icons.play_arrow_rounded,
                                    filled: true,
                                    onTap: () => _openEpisode(
                                      series: series,
                                      episodes: episodes,
                                      episode: firstEpisode,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (progressEpisode != null)
                  _ContinueWatchingBox(
                    progress: progress,
                    episode: progressEpisode,
                    onTap: () => _openEpisode(
                      series: series,
                      episodes: episodes,
                      episode: progressEpisode,
                    ),
                  ),

                const SizedBox(height: 20),

                ...grouped.entries.map((entry) {
                  final season = entry.key;
                  final seasonEpisodes = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temporada $season',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 150,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: seasonEpisodes.map((ep) {
                            return TvPosterCard(
                              title:
                              'Ep ${ep['episode_number']} - ${ep['title']}',
                              subtitle: ep['description']?.toString(),
                              imageUrl: ep['thumbnail_url']?.toString(),
                              onTap: () => _openEpisode(
                                series: series,
                                episodes: episodes,
                                episode: ep,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 26),
                    ],
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<int, List<Map<String, dynamic>>> _groupBySeason(
      List<Map<String, dynamic>> episodes,
      ) {
    final map = <int, List<Map<String, dynamic>>>{};

    for (final ep in episodes) {
      final season = (ep['season_number'] as num?)?.toInt() ?? 1;
      map.putIfAbsent(season, () => []).add(ep);
    }

    return map;
  }

  Map<String, dynamic>? _findProgressEpisode({
    required List<Map<String, dynamic>> episodes,
    required Map<String, dynamic>? progress,
  }) {
    if (progress == null) return null;

    final currentEpisodeId = progress['current_episode_id']?.toString();
    if (currentEpisodeId == null || currentEpisodeId.isEmpty) return null;

    for (final ep in episodes) {
      if (ep['id']?.toString() == currentEpisodeId) {
        return ep;
      }
    }

    return null;
  }

  void _openEpisode({
    required Map<String, dynamic> series,
    required List<Map<String, dynamic>> episodes,
    required Map<String, dynamic> episode,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TvSeriesEpisodePlayerScreen(
          series: series,
          episodes: episodes,
          initialEpisode: episode,
        ),
      ),
    );
  }
}

class _SeriesData {
  final Map<String, dynamic> series;
  final List<Map<String, dynamic>> episodes;
  final Map<String, dynamic>? progress;

  _SeriesData({
    required this.series,
    required this.episodes,
    required this.progress,
  });
}

class _ContinueWatchingBox extends StatelessWidget {
  final Map<String, dynamic>? progress;
  final Map<String, dynamic> episode;
  final VoidCallback onTap;

  const _ContinueWatchingBox({
    required this.progress,
    required this.episode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final watchedSeconds = (progress?['watched_seconds'] as num?)?.toInt() ?? 0;
    final season = (episode['season_number'] as num?)?.toInt() ?? 1;
    final episodeNumber = (episode['episode_number'] as num?)?.toInt() ?? 1;
    final title = episode['title']?.toString() ?? 'Episodio';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: Color(0xFF1E88FF),
            size: 42,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Continúa viendo • T$season E$episodeNumber • $title • $watchedSeconds s vistos',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          _TvButton(
            label: 'Abrir',
            icon: Icons.arrow_forward_rounded,
            filled: true,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _TvButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _TvButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_TvButton> createState() => _TvButtonState();
}

class _TvButtonState extends State<_TvButton> {
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focus = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.filled
                ? const Color(0xFF1E88FF)
                : (_focus ? Colors.blue : Colors.white10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focus
                  ? const Color(0xFF4FC3F7)
                  : const Color(0x22FFFFFF),
              width: _focus ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}