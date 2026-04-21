import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:red_cristiana/features/media/data/media_video_service.dart';
import 'package:red_cristiana/core/ads/video_banner_ad_card.dart';

class SeriesEpisodePlayerScreen extends StatefulWidget {
  final Map<String, dynamic> series;
  final List<Map<String, dynamic>> episodes;
  final Map<String, dynamic> initialEpisode;

  const SeriesEpisodePlayerScreen({
    super.key,
    required this.series,
    required this.episodes,
    required this.initialEpisode,
  });

  @override
  State<SeriesEpisodePlayerScreen> createState() =>
      _SeriesEpisodePlayerScreenState();
}

class _SeriesEpisodePlayerScreenState extends State<SeriesEpisodePlayerScreen> {
  YoutubePlayerController? _controller;

  late Map<String, dynamic> _currentEpisode;
  late List<Map<String, dynamic>> _episodes;

  Timer? _saveTimer;
  Timer? _nextEpisodeTimer;

  bool _isFullscreen = false;
  bool _handledEnd = false;
  bool _isSwitchingEpisode = false;
  int? _nextCountdown;
  int _currentSeason = 1;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _episodes = List<Map<String, dynamic>>.from(widget.episodes)
      ..sort((a, b) {
        final aSeason = (a['season_number'] as int?) ?? 1;
        final bSeason = (b['season_number'] as int?) ?? 1;
        if (aSeason != bSeason) return aSeason.compareTo(bSeason);

        final aEpisode = (a['episode_number'] as int?) ?? 1;
        final bEpisode = (b['episode_number'] as int?) ?? 1;
        return aEpisode.compareTo(bEpisode);
      });

    _currentEpisode = widget.initialEpisode;
    _currentSeason = (_currentEpisode['season_number'] as int?) ?? 1;

    final videoUrl = _currentEpisode['video_url']?.toString() ?? '';
    final videoId = _extractYoutubeId(videoUrl);

    if (videoId != null && videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          enableCaption: false,
        ),
      )..addListener(_listener);

      _saveTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        _persistProgress();
      });
    }
  }

  @override
  void dispose() {
    _persistProgress();
    _saveTimer?.cancel();
    _nextEpisodeTimer?.cancel();
    _controller?.removeListener(_listener);
    _controller?.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  String? _extractYoutubeId(String url) {
    return YoutubePlayer.convertUrlToId(url);
  }

  void _loadEpisode(Map<String, dynamic> episode) {
    if (!mounted) return;

    _saveTimer?.cancel();
    _nextEpisodeTimer?.cancel();

    _isSwitchingEpisode = true;
    _nextCountdown = null;
    _handledEnd = true;

    final videoUrl = episode['video_url']?.toString() ?? '';
    final videoId = _extractYoutubeId(videoUrl);

    if (videoId == null || videoId.isEmpty) return;

    if (_controller == null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          enableCaption: false,
        ),
      )..addListener(_listener);
    } else {
      _controller!.load(videoId);
    }

    setState(() {
      _currentEpisode = episode;
      _currentSeason = (episode['season_number'] as int?) ?? 1;
    });

    _saveTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _persistProgress();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _handledEnd = false;
      _isSwitchingEpisode = false;
    });
  }

  void _listener() {
    final controller = _controller;
    if (controller == null) return;

    final value = controller.value;

    if (value.isFullScreen != _isFullscreen && mounted) {
      setState(() {
        _isFullscreen = value.isFullScreen;
      });
    }

    if (_isSwitchingEpisode) return;

    if (value.playerState == PlayerState.playing && _handledEnd) {
      _handledEnd = false;
    }

    if (value.playerState == PlayerState.ended && !_handledEnd) {
      _handledEnd = true;
      _handleEpisodeEnded();
    }
  }

  Future<void> _persistProgress({bool completed = false}) async {
    final controller = _controller;
    if (controller == null) return;

    try {
      final watchedSeconds = controller.value.position.inSeconds;

      await MediaVideoService.saveSeriesProgress(
        seriesId: widget.series['id'].toString(),
        episodeId: _currentEpisode['id'].toString(),
        watchedSeconds: watchedSeconds,
        completed: completed,
      );
    } catch (_) {}
  }

  Map<String, dynamic>? _nextEpisode() {
    final currentIndex = _episodes.indexWhere(
          (e) => e['id']?.toString() == _currentEpisode['id']?.toString(),
    );

    if (currentIndex == -1) return null;
    if (currentIndex + 1 >= _episodes.length) return null;

    return _episodes[currentIndex + 1];
  }

  Future<void> _handleEpisodeEnded() async {
    if (_isSwitchingEpisode) return;

    await _persistProgress(completed: true);

    final next = _nextEpisode();
    if (next == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terminaste esta serie por ahora.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _nextCountdown = 5;
    });

    _nextEpisodeTimer?.cancel();
    _nextEpisodeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isSwitchingEpisode) {
        timer.cancel();
        return;
      }

      final secondsLeft = _nextCountdown ?? 0;

      if (secondsLeft <= 1) {
        timer.cancel();
        _playEpisode(next);
        return;
      }

      setState(() {
        _nextCountdown = secondsLeft - 1;
      });
    });
  }

  Future<void> _playEpisode(Map<String, dynamic> episode) async {
    await _persistProgress();
    if (!mounted) return;
    _loadEpisode(episode);
  }

  List<int> _seasonNumbers() {
    final seasons = _episodes
        .map((e) => (e['season_number'] as int?) ?? 1)
        .toSet()
        .toList()
      ..sort();
    return seasons;
  }

  List<Map<String, dynamic>> _episodesOfSeason(int season) {
    return _episodes
        .where((e) => ((e['season_number'] as int?) ?? 1) == season)
        .toList()
      ..sort((a, b) {
        final aEpisode = (a['episode_number'] as int?) ?? 1;
        final bEpisode = (b['episode_number'] as int?) ?? 1;
        return aEpisode.compareTo(bEpisode);
      });
  }

  void _goToPreviousSeason() {
    final seasons = _seasonNumbers();
    final index = seasons.indexOf(_currentSeason);
    if (index > 0) {
      setState(() {
        _currentSeason = seasons[index - 1];
      });
    }
  }

  void _goToNextSeason() {
    final seasons = _seasonNumbers();
    final index = seasons.indexOf(_currentSeason);
    if (index != -1 && index < seasons.length - 1) {
      setState(() {
        _currentSeason = seasons[index + 1];
      });
    }
  }

  Widget _buildSeasonNavigator() {
    final seasons = _seasonNumbers();
    final currentIndex = seasons.indexOf(_currentSeason);

    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex != -1 && currentIndex < seasons.length - 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: hasPrev ? _goToPreviousSeason : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: hasPrev ? const Color(0xFFEAF4FF) : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: hasPrev ? const Color(0xFF0D47A1) : Colors.black26,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1565C0),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_library_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Temporada $_currentSeason',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: hasNext ? _goToNextSeason : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: hasNext ? const Color(0xFF0D47A1) : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: hasNext ? Colors.white : Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeCarousel() {
    final seasonEpisodes = _episodesOfSeason(_currentSeason);
    final currentId = _currentEpisode['id']?.toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.play_circle_outline_rounded,
                color: Color(0xFF0D47A1),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Episodios · T$_currentSeason',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 205,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: seasonEpisodes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final episode = seasonEpisodes[index];
                final isCurrent = episode['id']?.toString() == currentId;
                final title = episode['title']?.toString() ?? 'Episodio';
                final thumb = episode['thumbnail_url']?.toString() ?? '';
                final number = episode['episode_number'] ?? 1;

                return InkWell(
                  onTap: () => _playEpisode(episode),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 185,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFFEAF4FF)
                          : const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF0D47A1)
                            : Colors.transparent,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        thumb.isNotEmpty
                            ? Image.network(
                          thumb,
                          width: double.infinity,
                          height: 102,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 102,
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.play_circle_outline, size: 34),
                            ),
                          ),
                        )
                            : Container(
                          height: 102,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.play_circle_outline, size: 34),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'E$number',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent
                                        ? const Color(0xFF0D47A1)
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.8,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? const Color(0xFF0D47A1)
                                        : const Color(0xFFDCEBFF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isCurrent ? 'Actual' : 'Ver',
                                    style: TextStyle(
                                      color: isCurrent
                                          ? Colors.white
                                          : const Color(0xFF0D47A1),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final title = _currentEpisode['title']?.toString() ?? 'Episodio';
    final season = _currentEpisode['season_number'] ?? 1;
    final number = _currentEpisode['episode_number'] ?? 1;
    final seriesTitle = widget.series['title']?.toString() ?? 'Serie';

    if (controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text(seriesTitle)),
        body: const Center(
          child: Text('No se pudo cargar este episodio.'),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: _isFullscreen ? Colors.black : const Color(0xFFF7F9FC),
          appBar: _isFullscreen
              ? null
              : AppBar(
            title: Text(seriesTitle),
            centerTitle: true,
            backgroundColor: const Color(0xFFF7F9FC),
          ),
          body: _isFullscreen
              ? Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: Center(child: player),
          )
              : ListView(
            children: [
              player,
              Container(
                margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temporada $season · Episodio $number',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      seriesTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_nextCountdown != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.skip_next_rounded,
                              color: Color(0xFF0D47A1),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Siguiente episodio en $_nextCountdown segundos...',
                                style: const TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildSeasonNavigator(),
              _buildEpisodeCarousel(),

              const VideoBannerAdCard(),

              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }
}