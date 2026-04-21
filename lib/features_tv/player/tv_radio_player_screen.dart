import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:red_cristiana/core/ads/ad_service.dart';
import 'package:red_cristiana/core/ads/ad_units.dart';
import 'package:red_cristiana/core/ads/video_banner_ad_card.dart';

class TvRadioPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> radio;

  const TvRadioPlayerScreen({
    super.key,
    required this.radio,
  });

  @override
  State<TvRadioPlayerScreen> createState() => _TvRadioPlayerScreenState();
}

class _TvRadioPlayerScreenState extends State<TvRadioPlayerScreen> {
  late final AudioPlayer _player;
  bool _loading = true;
  bool _playing = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    try {
      final url = widget.radio['stream_url']?.toString() ?? '';
      await _player.setUrl(url);
      await _player.play();

      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {
          _playing = state.playing;
        });
      });

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo reproducir esta radio.';
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
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
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.radio['name']?.toString() ?? 'Radio';
    final description = widget.radio['description']?.toString() ?? '';
    final logo = widget.radio['logo_url']?.toString();
    final location = [
      widget.radio['country']?.toString(),
      widget.radio['city']?.toString(),
    ].where((e) => (e ?? '').trim().isNotEmpty).join(' • ');

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
          child: Row(
            children: [
              Expanded(
                flex: 8,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0x22FFFFFF)),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F1725),
                        Color(0xFF14233A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TvPlayerHeader(
                          title: name,
                          onBack: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: const Color(0x22FFFFFF)),
                                color: const Color(0xFF111827),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: (logo != null && logo.isNotEmpty)
                                  ? Image.network(
                                logo,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const Icon(Icons.radio_rounded,
                                    size: 70, color: Colors.white70),
                              )
                                  : const Icon(Icons.radio_rounded,
                                  size: 70, color: Colors.white70),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (location.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      location,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                  if (description.trim().isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      description,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.45,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_loading)
                          const Center(child: CircularProgressIndicator())
                        else if (_error.isNotEmpty)
                          Text(
                            _error,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          )
                        else
                          Row(
                            children: [
                              _TvActionButton(
                                label: _playing ? 'Pausar' : 'Reproducir',
                                icon: _playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                onTap: _togglePlay,
                                filled: true,
                              ),
                              const SizedBox(width: 14),
                              _TvActionButton(
                                label: 'Apoyar',
                                icon: Icons.favorite_rounded,
                                onTap: _showSupportRewarded,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 360,
                child: Column(
                  children: const [
                    VideoBannerAdCard(),
                    SizedBox(height: 16),
                    Expanded(
                      child: _InfoPanel(
                        title: 'Radio en vivo',
                        description:
                        'Escucha emisoras cristianas en una experiencia adaptada para televisor. Luego aquí podremos agregar favoritos, radios relacionadas y accesos rápidos.',
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

class _TvPlayerHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TvPlayerHeader({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TvActionButton(
          label: 'Volver',
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final String description;

  const _InfoPanel({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _TvActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _TvActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_TvActionButton> createState() => _TvActionButtonState();
}

class _TvActionButtonState extends State<_TvActionButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: widget.filled
                ? const Color(0xFF1E88FF)
                : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _focused
                  ? const Color(0xFF4FC3F7)
                  : const Color(0x22FFFFFF),
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