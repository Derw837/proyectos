import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:red_cristiana/core/ads/ad_service.dart';
import 'package:red_cristiana/core/ads/ad_units.dart';
import 'package:red_cristiana/core/ads/video_banner_ad_card.dart';
import 'package:red_cristiana/features/radios/data/radio_service.dart';
import 'package:red_cristiana/features_tv/widgets/tv_poster_card.dart';

class TvRadiosScreen extends StatefulWidget {
  const TvRadiosScreen({super.key});

  @override
  State<TvRadiosScreen> createState() => _TvRadiosScreenState();
}

class _TvRadiosScreenState extends State<TvRadiosScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  late final AudioPlayer _player;

  final FocusNode _keyboardFocusNode = FocusNode();

  List<Map<String, dynamic>> _allRadios = [];
  List<Map<String, dynamic>> _filteredRadios = [];

  Map<String, dynamic>? _selectedRadio;
  int _selectedIndex = 0;

  bool _loadingPlayer = false;
  bool _isPlaying = false;
  String _error = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _future = _load();

    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final radios = await RadioService.getActiveRadios();

    _allRadios = radios;
    _applySearch();

    if (_filteredRadios.isNotEmpty && _selectedRadio == null) {
      _selectedIndex = 0;
      _selectedRadio = _filteredRadios.first;
    }

    return radios;
  }

  void _applySearch() {
    final q = _searchQuery.trim().toLowerCase();

    if (q.isEmpty) {
      _filteredRadios = List<Map<String, dynamic>>.from(_allRadios);
    } else {
      _filteredRadios = _allRadios.where((radio) {
        final name = radio['name']?.toString().toLowerCase() ?? '';
        final country = radio['country']?.toString().toLowerCase() ?? '';
        final city = radio['city']?.toString().toLowerCase() ?? '';
        final description =
            radio['description']?.toString().toLowerCase() ?? '';

        return name.contains(q) ||
            country.contains(q) ||
            city.contains(q) ||
            description.contains(q);
      }).toList();
    }

    if (_filteredRadios.isEmpty) {
      _selectedRadio = null;
      _selectedIndex = 0;
      _stopPlayback();
      return;
    }

    if (_selectedRadio == null) {
      _selectedIndex = 0;
      _selectedRadio = _filteredRadios.first;
      return;
    }

    final currentId = _selectedRadio!['id']?.toString();
    final foundIndex = _filteredRadios.indexWhere(
          (e) => e['id']?.toString() == currentId,
    );

    if (foundIndex >= 0) {
      _selectedIndex = foundIndex;
      _selectedRadio = _filteredRadios[foundIndex];
    } else {
      _selectedIndex = 0;
      _selectedRadio = _filteredRadios.first;
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _player.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _loadingPlayer = false;
      _error = '';
    });
  }

  Future<void> _playSelectedRadio() async {
    final radio = _selectedRadio;
    if (radio == null) return;

    final url = radio['stream_url']?.toString() ?? '';
    if (url.trim().isEmpty) {
      setState(() {
        _error = 'Esta emisora no tiene una URL de audio válida.';
      });
      return;
    }

    try {
      setState(() {
        _loadingPlayer = true;
        _error = '';
      });

      await _player.stop();
      await _player.setUrl(url);
      await _player.play();

      if (!mounted) return;
      setState(() {
        _loadingPlayer = false;
        _isPlaying = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPlayer = false;
        _isPlaying = false;
        _error = 'No se pudo reproducir esta emisora.';
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_selectedRadio == null) return;

    if (_loadingPlayer) return;

    if (_isPlaying) {
      await _player.pause();
    } else {
      final hasSource = _player.audioSource != null;
      if (hasSource) {
        await _player.play();
      } else {
        await _playSelectedRadio();
      }
    }
  }

  Future<void> _selectRadio(Map<String, dynamic> radio) async {
    final index = _filteredRadios.indexWhere(
          (e) => e['id']?.toString() == radio['id']?.toString(),
    );

    setState(() {
      _selectedRadio = radio;
      _selectedIndex = index >= 0 ? index : 0;
      _error = '';
    });

    await _playSelectedRadio();
  }

  Future<void> _playNext() async {
    if (_filteredRadios.isEmpty) return;

    final nextIndex = (_selectedIndex + 1) % _filteredRadios.length;
    await _selectRadio(_filteredRadios[nextIndex]);
  }

  Future<void> _playPrevious() async {
    if (_filteredRadios.isEmpty) return;

    final prevIndex =
        (_selectedIndex - 1 + _filteredRadios.length) % _filteredRadios.length;
    await _selectRadio(_filteredRadios[prevIndex]);
  }

  Future<void> _showSearchDialog() async {
    final controller = TextEditingController(text: _searchQuery);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF101826),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 760,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Buscar emisora',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF182234),
                    hintText: 'Escribe nombre, país o ciudad',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _DialogButton(
                      label: 'Cancelar',
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    _DialogButton(
                      label: 'Limpiar',
                      onTap: () => Navigator.pop(context, ''),
                    ),
                    const SizedBox(width: 12),
                    _DialogButton(
                      label: 'Buscar',
                      filled: true,
                      onTap: () => Navigator.pop(context, controller.text),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;

    setState(() {
      _searchQuery = result;
      _applySearch();
    });

    if (_selectedRadio != null) {
      await _playSelectedRadio();
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

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.mediaTrackNext ||
        event.logicalKey == LogicalKeyboardKey.channelUp) {
      _playNext();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.mediaTrackPrevious ||
        event.logicalKey == LogicalKeyboardKey.channelDown) {
      _playPrevious();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKey,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final selected = _selectedRadio;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 30),
              children: [
                const Text(
                  'Radios cristianas',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escucha emisoras en vivo, cambia rápidamente entre estaciones y apóyanos sin salir de la pantalla.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    _TopActionButton(
                      label: _searchQuery.trim().isEmpty
                          ? 'Buscar emisora'
                          : 'Buscar: ${_searchQuery.trim()}',
                      icon: Icons.search_rounded,
                      onTap: _showSearchDialog,
                    ),
                    const SizedBox(width: 12),
                    if (_searchQuery.trim().isNotEmpty)
                      _TopActionButton(
                        label: 'Quitar filtro',
                        icon: Icons.clear_rounded,
                        onTap: () async {
                          setState(() {
                            _searchQuery = '';
                            _applySearch();
                          });
                          if (_selectedRadio != null) {
                            await _playSelectedRadio();
                          }
                        },
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x22FFFFFF)),
                      ),
                      child: Text(
                        '${_filteredRadios.length} emisora${_filteredRadios.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                if (selected == null)
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: const Center(
                      child: Text(
                        'No encontramos emisoras con esa búsqueda.',
                        style: TextStyle(fontSize: 22, color: Colors.white),
                      ),
                    ),
                  )
                else
                  Container(
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
                      padding: const EdgeInsets.all(28),
                      child: Row(
                        children: [
                          Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0x22FFFFFF)),
                              color: const Color(0xFF111827),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: (selected['logo_url']?.toString().trim().isNotEmpty ?? false)
                                ? Image.network(
                              selected['logo_url'].toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.radio_rounded,
                                size: 72,
                                color: Colors.white70,
                              ),
                            )
                                : const Icon(
                              Icons.radio_rounded,
                              size: 72,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 26),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _InfoChip(
                                      label: 'Radio en vivo',
                                      filled: true,
                                    ),
                                    if ((selected['country']?.toString().trim().isNotEmpty ?? false))
                                      _InfoChip(
                                        label: selected['country'].toString(),
                                      ),
                                    if ((selected['city']?.toString().trim().isNotEmpty ?? false))
                                      _InfoChip(
                                        label: selected['city'].toString(),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  selected['name']?.toString() ?? 'Radio',
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  (selected['description']?.toString().trim().isNotEmpty ?? false)
                                      ? selected['description'].toString()
                                      : 'Disfruta esta emisora cristiana en una experiencia pensada para televisión.',
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.45,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (_error.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Text(
                                      _error,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    _PlayerActionButton(
                                      label: _loadingPlayer
                                          ? 'Cargando...'
                                          : (_isPlaying ? 'Pausar' : 'Reproducir'),
                                      icon: _loadingPlayer
                                          ? Icons.hourglass_top_rounded
                                          : (_isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded),
                                      filled: true,
                                      onTap: _togglePlay,
                                    ),
                                    const SizedBox(width: 12),
                                    _PlayerActionButton(
                                      label: 'Anterior',
                                      icon: Icons.skip_previous_rounded,
                                      onTap: _playPrevious,
                                    ),
                                    const SizedBox(width: 12),
                                    _PlayerActionButton(
                                      label: 'Siguiente',
                                      icon: Icons.skip_next_rounded,
                                      onTap: _playNext,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tip: algunos controles TV permiten cambiar emisora con Channel +/- o Next/Previous.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 168,
                  child: _filteredRadios.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filteredRadios.length,
                    itemBuilder: (context, index) {
                      final radio = _filteredRadios[index];
                      final subtitle = [
                        radio['country']?.toString(),
                        radio['city']?.toString(),
                      ].where((e) => (e ?? '').trim().isNotEmpty).join(' • ');

                      return TvPosterCard(
                        title: radio['name']?.toString() ?? 'Radio',
                        subtitle: subtitle.isEmpty ? 'En vivo' : subtitle,
                        imageUrl: radio['logo_url']?.toString(),
                        width: 240,
                        height: 150,
                        onTap: () => _selectRadio(radio),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: VideoBannerAdCard(),
                    ),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 320,
                      child: _SupportCard(
                        onTap: _showSupportRewarded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_TopActionButton> createState() => _TopActionButtonState();
}

class _TopActionButtonState extends State<_TopActionButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        setState(() {
          _focused = value;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
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

class _PlayerActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _PlayerActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_PlayerActionButton> createState() => _PlayerActionButtonState();
}

class _PlayerActionButtonState extends State<_PlayerActionButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        setState(() {
          _focused = value;
        });
      },
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

class _InfoChip extends StatelessWidget {
  final String label;
  final bool filled;

  const _InfoChip({
    required this.label,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF1E88FF) : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SupportCard extends StatefulWidget {
  final VoidCallback onTap;

  const _SupportCard({
    required this.onTap,
  });

  @override
  State<_SupportCard> createState() => _SupportCardState();
}

class _SupportCardState extends State<_SupportCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        setState(() {
          _focused = value;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0D47A1),
                Color(0xFF1565C0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _focused
                  ? const Color(0xFF4FC3F7)
                  : const Color(0x22FFFFFF),
              width: _focused ? 2 : 1,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(height: 12),
              Text(
                'Apóyanos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Mira un video corto y ayuda a mantener Red Cristiana gratuita para todos.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Ver video de apoyo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _DialogButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        setState(() {
          _focused = value;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: widget.filled
                ? const Color(0xFF1E88FF)
                : Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focused
                  ? const Color(0xFF4FC3F7)
                  : const Color(0x24FFFFFF),
              width: _focused ? 2 : 1,
            ),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}