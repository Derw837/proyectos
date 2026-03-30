import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF7F9FC),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      if (widget.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.description,
                          style: const TextStyle(
                            fontSize: 15.5,
                            height: 1.5,
                            color: Colors.black87,
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
      },
    );
  }
}