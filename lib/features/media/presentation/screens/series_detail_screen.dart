import 'package:flutter/material.dart';
import 'package:red_cristiana/features/media/data/media_video_service.dart';
import 'package:red_cristiana/features/media/presentation/screens/series_episode_player_screen.dart';
import 'package:red_cristiana/core/ads/video_banner_ad_card.dart';

class SeriesDetailScreen extends StatefulWidget {
  final String seriesId;

  const SeriesDetailScreen({
    super.key,
    required this.seriesId,
  });

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  bool isLoading = true;
  String errorMessage = '';

  Map<String, dynamic>? series;
  Map<String, dynamic>? progress;
  List<Map<String, dynamic>> episodes = [];
  int? _openSeason;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final seriesData = await MediaVideoService.getSeriesById(widget.seriesId);
      final episodesData = await MediaVideoService.getSeriesEpisodes(widget.seriesId);
      final progressData = await MediaVideoService.getSeriesProgress(widget.seriesId);

      if (!mounted) return;

      setState(() {
        series = seriesData;
        episodes = episodesData;
        progress = progressData;
        _openSeason = null;
        _showFullDescription = false;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'No pudimos cargar esta serie. Inténtalo otra vez.';
      });
    }
  }

  Map<int, List<Map<String, dynamic>>> _episodesBySeason() {
    final map = <int, List<Map<String, dynamic>>>{};

    for (final episode in episodes) {
      final season = (episode['season_number'] as int?) ?? 1;
      map.putIfAbsent(season, () => []);
      map[season]!.add(episode);
    }

    for (final entry in map.entries) {
      entry.value.sort((a, b) {
        final aEpisode = (a['episode_number'] as int?) ?? 1;
        final bEpisode = (b['episode_number'] as int?) ?? 1;
        return aEpisode.compareTo(bEpisode);
      });
    }

    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Map<String, dynamic>? _findEpisodeById(String? id) {
    if (id == null) return null;
    for (final episode in episodes) {
      if (episode['id']?.toString() == id) return episode;
    }
    return null;
  }

  Future<void> _openEpisode(Map<String, dynamic> episode) async {
    if (series == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeriesEpisodePlayerScreen(
          series: series!,
          episodes: episodes,
          initialEpisode: episode,
        ),
      ),
    );

    _load();
  }

  Widget _buildTopCard() {
    final s = series!;
    final title = s['title']?.toString() ?? 'Serie';
    final description = s['description']?.toString() ?? '';
    final coverUrl = (s['cover_url']?.toString().trim().isNotEmpty ?? false)
        ? s['cover_url'].toString()
        : (s['thumbnail_url']?.toString() ?? '');

    final progressEpisode = _findEpisodeById(progress?['current_episode_id']?.toString());

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coverUrl.isNotEmpty)
            Image.network(
              coverUrl,
              width: double.infinity,
              height: 210,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: double.infinity,
                height: 210,
                color: Colors.grey.shade300,
                child: const Icon(Icons.tv, size: 60),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 210,
              color: Colors.grey.shade300,
              child: const Icon(Icons.tv, size: 60),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Serie',
                        style: TextStyle(
                          color: Color(0xFF0D47A1),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${episodes.length} episodio${episodes.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.18,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    maxLines: _showFullDescription ? null : 2,
                    overflow: _showFullDescription ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showFullDescription = !_showFullDescription;
                      });
                    },
                    child: Text(
                      _showFullDescription ? 'Ver menos' : 'Ver más',
                      style: const TextStyle(
                        color: Color(0xFF0D47A1),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (progressEpisode != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openEpisode(progressEpisode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.play_circle_fill),
                      label: Text(
                        'Continuar · T${progressEpisode['season_number']} E${progressEpisode['episode_number']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                else if (episodes.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openEpisode(episodes.first),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Empezar a ver',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

  Widget _episodeCard(Map<String, dynamic> episode, {bool isCurrent = false}) {
    final title = episode['title']?.toString() ?? 'Episodio';
    final description = episode['description']?.toString() ?? '';
    final thumb = episode['thumbnail_url']?.toString() ?? '';
    final season = episode['season_number'] ?? 1;
    final number = episode['episode_number'] ?? 1;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openEpisode(episode),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFFEAF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCurrent ? const Color(0xFF0D47A1) : Colors.transparent,
            width: 1.1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            thumb.isNotEmpty
                ? Image.network(
              thumb,
              width: double.infinity,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: double.infinity,
                height: 96,
                color: Colors.grey.shade300,
                child: const Icon(Icons.play_circle_outline, size: 34),
              ),
            )
                : Container(
              width: double.infinity,
              height: 96,
              color: Colors.grey.shade300,
              child: const Icon(Icons.play_circle_outline, size: 34),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'T$season · E$number',
                      style: TextStyle(
                        color: isCurrent ? const Color(0xFF0D47A1) : Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.2,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.8,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonSection(
      int season,
      List<Map<String, dynamic>> seasonEpisodes,
      String? currentEpisodeId,
      ) {
    final isOpen = _openSeason == season;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _openSeason = isOpen ? null : season;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Temporada $season',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${seasonEpisodes.length} episodio${seasonEpisodes.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 215,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: seasonEpisodes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final episode = seasonEpisodes[index];
                  final isCurrent =
                      episode['id']?.toString() == currentEpisodeId;
                  return _episodeCard(
                    episode,
                    isCurrent: isCurrent,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _episodesBySeason();
    final currentEpisodeId = progress?['current_episode_id']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(series?['title']?.toString() ?? 'Serie'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : series == null
          ? const Center(child: Text('No encontramos la serie.'))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildTopCard(),
            for (final entry in grouped.entries) ...[
              _buildSeasonSection(
                entry.key,
                entry.value,
                currentEpisodeId,
              ),
            ],

            const VideoBannerAdCard(),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}