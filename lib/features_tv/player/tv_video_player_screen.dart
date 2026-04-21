import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_cristiana/core/ads/ad_service.dart';
import 'package:red_cristiana/core/ads/ad_units.dart';
import 'package:red_cristiana/core/ads/video_banner_ad_card.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TvVideoPlayerScreen extends StatefulWidget {
  final String title;
  final String description;
  final String videoUrl;

  const TvVideoPlayerScreen({
    super.key,
    required this.title,
    required this.description,
    required this.videoUrl,
  });

  @override
  State<TvVideoPlayerScreen> createState() => _TvVideoPlayerScreenState();
}

class _TvVideoPlayerScreenState extends State<TvVideoPlayerScreen> {
  YoutubePlayerController? _controller;
  bool _showOverlay = true;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final videoId = _extractYoutubeId(widget.videoUrl);
    if (videoId != null && videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          enableCaption: true,
          hideControls: false,
        ),
      )..addListener(_listener);
    }
  }

  String? _extractYoutubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtube.com')) {
      if ((uri.queryParameters['v'] ?? '').trim().isNotEmpty) {
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

    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }

    return YoutubePlayer.convertUrlToId(url);
  }

  void _listener() {
    if (!mounted || _controller == null) return;

    final ready = _controller!.value.isReady;
    if (ready != _isReady) {
      setState(() {
        _isReady = ready;
      });
    }
  }

  Future<void> _showSupportRewarded() async {
    final shown = await AdService.showRewardedAd(
      adUnitId: AdUnits.rewardedVideoSupport,
      onRewardEarned: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gracias por apoyar Red Cristiana'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );

    if (!shown && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El video de apoyo aún no está listo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_listener);
    _controller?.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF070B14),
        body: Center(
          child: Container(
            width: 820,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF101826),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white70, size: 60),
                SizedBox(height: 16),
                Text(
                  'No se pudo cargar este video en TV.',
                  style: TextStyle(fontSize: 24, color: Colors.white),
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
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(child: player),

              if (_showOverlay)
                Positioned(
                  top: 24,
                  left: 24,
                  right: 24,
                  child: _TvPlayerTopBar(
                    title: widget.title,
                    onBack: () => Navigator.pop(context),
                    onSupport: _showSupportRewarded,
                  ),
                ),

              if (_showOverlay)
                Positioned(
                  right: 28,
                  bottom: 28,
                  child: SizedBox(
                    width: 380,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const VideoBannerAdCard(),
                        const SizedBox(height: 12),
                        _TvOverlayInfo(
                          title: widget.title,
                          description: widget.description,
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                left: 24,
                bottom: 24,
                child: _OverlayToggleButton(
                  label: _showOverlay ? 'Ocultar panel' : 'Mostrar panel',
                  icon: _showOverlay
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  onTap: () {
                    setState(() {
                      _showOverlay = !_showOverlay;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TvPlayerTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onSupport;

  const _TvPlayerTopBar({
    required this.title,
    required this.onBack,
    required this.onSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OverlayToggleButton(
          label: 'Volver',
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.50),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Text(
              title.isEmpty ? 'Video' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _OverlayToggleButton(
          label: 'Apoyar',
          icon: Icons.favorite_rounded,
          onTap: onSupport,
        ),
      ],
    );
  }
}

class _TvOverlayInfo extends StatelessWidget {
  final String title;
  final String description;

  const _TvOverlayInfo({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.56),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverlayToggleButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayToggleButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_OverlayToggleButton> createState() => _OverlayToggleButtonState();
}

class _OverlayToggleButtonState extends State<_OverlayToggleButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.56),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focused
                  ? const Color(0xFF4FC3F7)
                  : const Color(0x33FFFFFF),
              width: _focused ? 2 : 1,
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