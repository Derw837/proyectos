import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:red_cristiana/core/ads/video_banner_ad_card.dart';
import 'package:red_cristiana/core/ads/ad_service.dart';
import 'package:red_cristiana/core/ads/ad_units.dart';

class AppVideoPlayerScreen extends StatefulWidget {
  final String title;
  final String description;
  final String videoUrl;

  const AppVideoPlayerScreen({
    super.key,
    required this.title,
    required this.description,
    required this.videoUrl,
  });

  @override
  State<AppVideoPlayerScreen> createState() => _AppVideoPlayerScreenState();
}

class _AppVideoPlayerScreenState extends State<AppVideoPlayerScreen> {
  YoutubePlayerController? _controller;
  bool _isFullscreen = false;
  bool _isYoutube = false;
  bool _isDescriptionExpanded = false;

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

    final videoId = _extractYoutubeId(widget.videoUrl);

    if (videoId != null && videoId.isNotEmpty) {
      _isYoutube = true;

      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          enableCaption: true,
        ),
      )..addListener(_videoListener);
    }
  }

  String? _extractYoutubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtube.com')) {
      if (uri.queryParameters['v'] != null &&
          uri.queryParameters['v']!.trim().isNotEmpty) {
        return uri.queryParameters['v'];
      }

      if (uri.pathSegments.contains('live') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }

      if (uri.pathSegments.contains('embed') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }

      if (uri.pathSegments.contains('shorts') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    }

    if (uri.host.contains('youtu.be')) {
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
    }

    return YoutubePlayer.convertUrlToId(url);
  }

  void _videoListener() {
    if (_controller == null) return;

    final value = _controller!.value;

    if (value.isFullScreen != _isFullscreen && mounted) {
      setState(() {
        _isFullscreen = value.isFullScreen;
      });
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el video')),
      );
    }
  }

  Future<void> _showSupportRewarded() async {
    final shown = await AdService.showRewardedAd(
      adUnitId: AdUnits.rewardedVideoSupport,
      onRewardEarned: () {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🙏 Gracias por apoyar este contenido'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );

    if (!shown && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El video de apoyo aún no está listo. Inténtalo de nuevo en unos segundos.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription = widget.description.trim().isNotEmpty;
    final fullDescription = widget.description.trim();
    final shortDescription = fullDescription.length > 180
        ? '${fullDescription.substring(0, 180)}...'
        : fullDescription;

    if (_controller == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: Text(widget.title.isEmpty ? 'Video' : widget.title),
          centerTitle: true,
          backgroundColor: const Color(0xFFF7F9FC),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No se pudo cargar el video dentro de la app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                if (widget.videoUrl.trim().isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _openExternally,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir externamente'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor:
          _isFullscreen ? Colors.black : const Color(0xFFF7F9FC),
          appBar: _isFullscreen
              ? null
              : AppBar(
            title: Text(widget.title.isEmpty ? 'Video' : widget.title),
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
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                player,
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title.trim().isEmpty
                                  ? 'Video'
                                  : widget.title.trim(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                              ),
                            ),
                            if (hasDescription) ...[
                              const SizedBox(height: 14),
                              const Text(
                                'Sinopsis',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5F6B7A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isDescriptionExpanded
                                    ? fullDescription
                                    : shortDescription,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                              if (fullDescription.length > 180) ...[
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isDescriptionExpanded =
                                      !_isDescriptionExpanded;
                                    });
                                  },
                                  child: Text(
                                    _isDescriptionExpanded
                                        ? 'Ver menos'
                                        : 'Ver más',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0D47A1),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),

                      const VideoBannerAdCard(),

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
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
                              color: Color(0x22000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Apoya este contenido',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Mira un video corto y ayúdanos a mantener Red Cristiana gratuita para todos.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 13.5,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showSupportRewarded,
                                icon: const Icon(Icons.ondemand_video_rounded),
                                label: const Text('Ver video de apoyo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0D47A1),
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}