import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_cristiana/core/utils/network_status_helper.dart';
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
  bool _isRetrying = false;
  Timer? _hideTimer;

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

    _initVideo();
    _startAutoHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _disposeController();
    WakelockPlus.disable();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;

    if (controller != null) {
      try {
        await controller.pause();
      } catch (_) {}

      try {
        await controller.dispose();
      } catch (_) {}
    }
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
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _disposeController();

      final controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

      _controller = controller;

      await controller.initialize();
      await controller.play();
      await WakelockPlus.enable();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      await WakelockPlus.disable();

      final friendlyMessage =
      await NetworkStatusHelper.playerMessageForError(e);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = friendlyMessage;
      });
    }
  }

  Future<void> _retryVideo() async {
    if (_isRetrying) return;

    try {
      setState(() {
        _isRetrying = true;
        _isLoading = true;
        _error = null;
      });

      await _disposeController();
      await Future.delayed(const Duration(milliseconds: 250));
      await _initVideo();
    } finally {
      if (!mounted) return;
      setState(() {
        _isRetrying = false;
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 58,
              ),
              const SizedBox(height: 14),
              const Text(
                'No se pudo reproducir este video',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _error ?? 'Ocurrió un problema inesperado.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _isRetrying ? null : _retryVideo,
                icon: _isRetrying
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.refresh),
                label: Text(
                  _isRetrying ? 'Reintentando...' : 'Volver a intentarlo',
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Volver',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
                  ? _buildErrorView()
                  : controller == null
                  ? _buildErrorView()
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
                            final orientation =
                                MediaQuery.of(context).orientation;
                            if (orientation == Orientation.landscape) {
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.portraitUp,
                                DeviceOrientation.portraitDown,
                              ]);
                              SystemChrome.setEnabledSystemUIMode(
                                SystemUiMode.edgeToEdge,
                              );
                            } else {
                              await WakelockPlus.disable();
                              if (mounted) Navigator.pop(context);
                            }
                          },
                          icon:
                          const Icon(Icons.arrow_back, color: Colors.white),
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
                        if (_error == null)
                          IconButton(
                            onPressed: _toggleFullscreen,
                            icon: Icon(
                              isLandscape
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
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
                          color: Colors.black.withValues(alpha: 0.75),
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
                                  style:
                                  const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  _format(controller.value.duration),
                                  style:
                                  const TextStyle(color: Colors.white70),
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