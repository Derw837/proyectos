import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class NetworkVideoPlayerScreen extends StatefulWidget {
  final String title;
  final String description;
  final String videoUrl;

  const NetworkVideoPlayerScreen({
    super.key,
    required this.title,
    required this.description,
    required this.videoUrl,
  });

  @override
  State<NetworkVideoPlayerScreen> createState() =>
      _NetworkVideoPlayerScreenState();
}

class _NetworkVideoPlayerScreenState extends State<NetworkVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _showControls = true;
  String? _error;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _startAutoHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.dispose();
    WakelockPlus.disable();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  void _startAutoHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _showControls = false;
      });
    });
  }

  void _showUI() {
    setState(() {
      _showControls = true;
    });
    _startAutoHideTimer();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
      await _controller!.play();
      await WakelockPlus.enable();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      await WakelockPlus.disable();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'No se pudo reproducir este video.\n$e';
      });
    }
  }

  void _toggleFullscreen() {
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    _showUI();
  }

  Future<void> _seekForward() async {
    final controller = _controller;
    if (controller == null) return;

    final value = controller.value;
    final max = value.duration;
    final next = value.position + const Duration(seconds: 10);
    await controller.seekTo(next > max ? max : next);
    _showUI();
  }

  Future<void> _seekBackward() async {
    final controller = _controller;
    if (controller == null) return;

    final value = controller.value;
    final back = value.position - const Duration(seconds: 10);
    await controller.seekTo(back < Duration.zero ? Duration.zero : back);
    _showUI();
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '${d.inMinutes}:${s}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_showControls) {
            setState(() => _showControls = false);
          } else {
            _showUI();
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
                  : controller == null
                  ? const Center(
                child: Text(
                  'No se pudo iniciar el reproductor',
                  style: TextStyle(color: Colors.white),
                ),
              )
                  : Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio == 0
                      ? 16 / 9
                      : controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            ),

            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _showControls ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final orientation = MediaQuery.of(context).orientation;
                            if (orientation == Orientation.landscape) {
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.portraitUp,
                                DeviceOrientation.portraitDown,
                              ]);
                              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                            } else {
                              await WakelockPlus.disable();
                              if (mounted) Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleFullscreen,
                          icon: Icon(
                            isLandscape ? Icons.fullscreen_exit : Icons.fullscreen,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (!_isLoading && _error == null && controller != null)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showControls ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isLandscape) ...[
                              Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (widget.description.trim().isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  widget.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                            ],
                            VideoProgressIndicator(
                              controller,
                              allowScrubbing: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _format(controller.value.position),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  _format(controller.value.duration),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _seekBackward,
                                  icon: const Icon(
                                    Icons.replay_10,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  onPressed: () async {
                                    if (controller.value.isPlaying) {
                                      await controller.pause();
                                    } else {
                                      await controller.play();
                                    }
                                    if (mounted) setState(() {});
                                    _showUI();
                                  },
                                  icon: Icon(
                                    controller.value.isPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 42,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  onPressed: _seekForward,
                                  icon: const Icon(
                                    Icons.forward_10,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}