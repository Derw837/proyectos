import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class NetworkStreamPlayerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> channels;
  final int initialIndex;

  const NetworkStreamPlayerScreen({
    super.key,
    required this.channels,
    required this.initialIndex,
  });

  @override
  State<NetworkStreamPlayerScreen> createState() =>
      _NetworkStreamPlayerScreenState();
}

class _NetworkStreamPlayerScreenState extends State<NetworkStreamPlayerScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;

  int _currentIndex = 0;
  bool _showControls = true;
  bool _showChannelDrawer = false;

  Timer? _hideTimer;

  Map<String, dynamic> get currentChannel => widget.channels[_currentIndex];

  String get currentTitle => currentChannel['name']?.toString() ?? 'TV en vivo';
  String get currentDescription =>
      currentChannel['description']?.toString() ?? '';
  String get currentUrl => currentChannel['stream_url']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _initVideo();
    _startAutoHideTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      WakelockPlus.disable();
    }
  }

  @override
  void didChangeMetrics() {
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.landscape) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _startAutoHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _showControls = false;
        _showChannelDrawer = false;
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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _controller?.dispose();

      _controller = VideoPlayerController.networkUrl(Uri.parse(currentUrl));
      await _controller!.initialize();
      await _controller!.setLooping(false);
      await _controller!.play();

      await WakelockPlus.enable();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showUI();
    } catch (e) {
      await WakelockPlus.disable();

      if (!mounted) return;

      setState(() {
        _error = 'No se pudo reproducir este canal.\n$e';
        _isLoading = false;
      });

      _showUI();
    }
  }

  Future<void> _goToChannel(int index) async {
    if (index < 0 || index >= widget.channels.length) return;

    setState(() {
      _currentIndex = index;
      _showChannelDrawer = false;
    });

    await _initVideo();
  }

  Future<void> _nextChannel() async {
    if (widget.channels.isEmpty) return;
    final next = (_currentIndex + 1) % widget.channels.length;
    await _goToChannel(next);
  }

  Future<void> _previousChannel() async {
    if (widget.channels.isEmpty) return;
    final prev = (_currentIndex - 1 + widget.channels.length) % widget.channels.length;
    await _goToChannel(prev);
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

  Widget _buildChannelDrawer() {
    return Positioned(
      right: 10,
      top: 64,
      bottom: 14,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _showChannelDrawer ? 1 : 0,
        child: IgnorePointer(
          ignoring: !_showChannelDrawer,
          child: Container(
            width: 190,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.86),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Text(
                    'Canales',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: widget.channels.length,
                    itemBuilder: (context, index) {
                      final channel = widget.channels[index];
                      final logo = channel['logo_url']?.toString() ?? '';
                      final name = channel['name']?.toString() ?? '';
                      final selected = index == _currentIndex;

                      return InkWell(
                        onTap: () => _goToChannel(index),
                        child: Container(
                          height: 58,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withOpacity(0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(color: Colors.white24)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: logo.isNotEmpty
                                    ? Image.network(
                                  logo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(
                                    Icons.live_tv,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                )
                                    : const Icon(
                                  Icons.live_tv,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 12.5,
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
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isLandscape) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _showControls ? 1 : 0,
      child: IgnorePointer(
        ignoring: !_showControls,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
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
                    currentTitle,
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
                  onPressed: () {
                    setState(() {
                      _showChannelDrawer = !_showChannelDrawer;
                    });
                    _showUI();
                  },
                  icon: const Icon(Icons.view_list, color: Colors.white),
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
    );
  }

  Widget _buildBottomControls(bool isLandscape) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _showControls ? 1 : 0,
      child: IgnorePointer(
        ignoring: !_showControls,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isLandscape) ...[
                    Text(
                      currentTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (currentDescription.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        currentDescription,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _previousChannel,
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.45)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.live_tv,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'EN VIVO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      IconButton(
                        onPressed: _nextChannel,
                        icon: const Icon(
                          Icons.skip_next,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showChannelDrawer = !_showChannelDrawer;
                            });
                            _showUI();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.view_carousel),
                          label: const Text('Ver canales'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_showControls) {
            setState(() {
              _showControls = false;
              _showChannelDrawer = false;
            });
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
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
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
            _buildTopBar(isLandscape),
            _buildBottomControls(isLandscape),
            _buildChannelDrawer(),
          ],
        ),
      ),
    );
  }
}