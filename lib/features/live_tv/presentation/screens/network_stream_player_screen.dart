import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_cristiana/core/ads/ad_service.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:red_cristiana/core/ads/ad_units.dart';

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
  bool _wasPlayingBeforePause = false;
  bool _isRestoringFromLifecycle = false;

  Map<String, dynamic> get currentChannel => widget.channels[_currentIndex];

  String get currentTitle => currentChannel['name']?.toString() ?? 'TV en vivo';
  String get currentDescription =>
      currentChannel['description']?.toString() ?? '';
  String get currentUrl => currentChannel['stream_url']?.toString() ?? '';

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _initVideo();
    _startAutoHideTimer();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    WidgetsBinding.instance.removeObserver(this);
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

  String _friendlyErrorMessage(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('source error')) {
      return 'Canal no disponible por este momento.';
    }

    if (text.contains('mediacodecaudiorenderer') ||
        text.contains('audio renderer')) {
      return 'Ocurrió un problema al restaurar el audio/video del canal. Toca "Reintentar".';
    }

    if (text.contains('behindlivewindowexception')) {
      return 'La transmisión se desfasó. Toca "Reintentar".';
    }

    if (text.contains('network') || text.contains('socket')) {
      return 'Problema de conexión. Revisa internet e inténtalo nuevamente.';
    }

    return 'No se pudo reproducir este canal por este momento.';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final controller = _controller;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _wasPlayingBeforePause = controller?.value.isPlaying ?? false;
      await WakelockPlus.disable();
      await _disposeController();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      await WakelockPlus.enable();

      if (!_isRestoringFromLifecycle) {
        _isRestoringFromLifecycle = true;
        try {
          await _initVideo(autoPlay: _wasPlayingBeforePause || true);
        } finally {
          _isRestoringFromLifecycle = false;
        }
      }
    }
  }

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize;
    final isLandscape = size.width > size.height;

    if (isLandscape) {
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

  Future<void> _initVideo({bool autoPlay = true}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _disposeController();

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(currentUrl),
      );

      _controller = controller;

      await controller.initialize();
      await controller.setLooping(false);

      if (autoPlay) {
        await controller.play();
      }

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
        _error = _friendlyErrorMessage(e);
        _isLoading = false;
      });

      _showUI();
    }
  }

  Future<void> _retryCurrentChannel() async {
    await _initVideo(autoPlay: true);
  }

  Future<void> _goToChannel(int index) async {
    if (index < 0 || index >= widget.channels.length) return;

    setState(() {
      _currentIndex = index;
      _showChannelDrawer = false;
    });

    await _initVideo(autoPlay: true);
  }

  Future<void> _nextChannel() async {
    if (widget.channels.isEmpty) return;
    final next = (_currentIndex + 1) % widget.channels.length;
    await _goToChannel(next);
  }

  Future<void> _previousChannel() async {
    if (widget.channels.isEmpty) return;
    final prev = (_currentIndex - 1 + widget.channels.length) %
        widget.channels.length;
    await _goToChannel(prev);
  }

  Future<void> _openSupportChannel() async {
    setState(() {
      _showChannelDrawer = false;
    });

    final shown = await AdService.showRewardedAd(
      adUnitId: AdUnits.rewardedTvSupport,
      onRewardEarned: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🙏 Gracias por apoyar Red Cristiana'),
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

    _showUI();
  }

  void _toggleFullscreen() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize;
    final isLandscape = size.width > size.height;

    if (!isLandscape) {
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.tv_off,
              color: Colors.white70,
              size: 54,
            ),
            const SizedBox(height: 18),
            Text(
              _error ?? 'No se pudo reproducir este canal.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _retryCurrentChannel,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
                OutlinedButton.icon(
                  onPressed: _nextChannel,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Otro canal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportChannelCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _openSupportChannel,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Canal de apoyo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mira un video corto y ayúdanos a mantener esta señal gratuita para todos.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 12.2,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'Ver video de apoyo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            width: 210,
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

                _buildSupportChannelCard(),

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
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.all(8),
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
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: logo.isNotEmpty
                                    ? Image.network(
                                  logo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(
                                    Icons.live_tv,
                                    color: Colors.white70,
                                  ),
                                )
                                    : const Icon(
                                  Icons.live_tv,
                                  color: Colors.white70,
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
                    final view =
                        WidgetsBinding.instance.platformDispatcher.views.first;
                    final size = view.physicalSize;
                    final landscape = size.width > size.height;

                    if (landscape) {
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
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.45),
                          ),
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
            _buildTopBar(isLandscape),
            _buildBottomControls(isLandscape),
            _buildChannelDrawer(),
          ],
        ),
      ),
    );
  }
}