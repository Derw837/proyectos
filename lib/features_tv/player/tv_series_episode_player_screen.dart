import 'package:flutter/material.dart';
import 'package:red_cristiana/features/media/data/media_video_service.dart';
import 'package:red_cristiana/features_tv/player/tv_video_player_screen.dart';

class TvSeriesEpisodePlayerScreen extends StatefulWidget {
  final Map<String, dynamic> series;
  final List<Map<String, dynamic>> episodes;
  final Map<String, dynamic> initialEpisode;

  const TvSeriesEpisodePlayerScreen({
    super.key,
    required this.series,
    required this.episodes,
    required this.initialEpisode,
  });

  @override
  State<TvSeriesEpisodePlayerScreen> createState() =>
      _TvSeriesEpisodePlayerScreenState();
}

class _TvSeriesEpisodePlayerScreenState
    extends State<TvSeriesEpisodePlayerScreen> {
  late Map<String, dynamic> _currentEpisode;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.initialEpisode;
  }

  Future<void> _saveProgress() async {
    final seriesId = widget.series['id']?.toString() ?? '';
    final episodeId = _currentEpisode['id']?.toString() ?? '';
    if (seriesId.isEmpty || episodeId.isEmpty) return;

    await MediaVideoService.saveSeriesProgress(
      seriesId: seriesId,
      episodeId: episodeId,
      watchedSeconds: 30,
      completed: false,
    );
  }

  void _changeEpisode(Map<String, dynamic> episode) async {
    setState(() {
      _currentEpisode = episode;
    });

    await _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    final title = _currentEpisode['title']?.toString() ?? 'Episodio';
    final description = _currentEpisode['description']?.toString() ?? '';
    final videoUrl = _currentEpisode['video_url']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          Expanded(
            flex: 10,
            child: TvVideoPlayerScreen(
              title:
              '${widget.series['title'] ?? 'Serie'} · ${_episodeLabel(_currentEpisode)} · $title',
              description: description,
              videoUrl: videoUrl,
            ),
          ),
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1320),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.series['title']?.toString() ?? 'Serie',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Episodios',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: widget.episodes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final ep = widget.episodes[index];
                        final active =
                            ep['id']?.toString() == _currentEpisode['id']?.toString();

                        return _TvEpisodeTile(
                          title: ep['title']?.toString() ?? 'Episodio',
                          subtitle: _episodeLabel(ep),
                          active: active,
                          onTap: () => _changeEpisode(ep),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    child: _TvEpisodeTile(
                      title: 'Volver a la serie',
                      subtitle: 'Cerrar reproductor',
                      active: false,
                      onTap: () => Navigator.pop(context),
                      icon: Icons.arrow_back_rounded,
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

  String _episodeLabel(Map<String, dynamic> ep) {
    final season = (ep['season_number'] as num?)?.toInt() ?? 1;
    final number = (ep['episode_number'] as num?)?.toInt() ?? 1;
    return 'T$season · E$number';
  }
}

class _TvEpisodeTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  const _TvEpisodeTile({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  State<_TvEpisodeTile> createState() => _TvEpisodeTileState();
}

class _TvEpisodeTileState extends State<_TvEpisodeTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.active || _focused;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1E88FF) : const Color(0xFF121B2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF4FC3F7)
                  : const Color(0x20FFFFFF),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon ?? Icons.play_arrow_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}