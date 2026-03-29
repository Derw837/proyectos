import 'dart:async';
import 'package:flutter/material.dart';
import 'package:red_cristiana/core/audio/audio_player_service.dart';
import 'package:red_cristiana/features/radios/data/radio_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RadiosScreen extends StatefulWidget {
  const RadiosScreen({super.key});

  @override
  State<RadiosScreen> createState() => _RadiosScreenState();
}

class _RadiosScreenState extends State<RadiosScreen> {
  bool isLoading = true;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> allRadios = [];
  List<Map<String, dynamic>> filteredRadios = [];

  String selectedMode = 'all';
  String? expandedRadioId;

  Timer? _playCountTimer;
  String? _countingRadioId;
  final Set<String> _alreadyCountedThisSession = {};

  @override
  void initState() {
    super.initState();
    _loadRadios();
    searchController.addListener(_applyFilters);
    AudioPlayerService.init();
  }

  @override
  void dispose() {
    _playCountTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRadios() async {
    try {
      final data = await RadioService.getActiveRadios();

      if (!mounted) return;
      setState(() {
        allRadios = data;
        filteredRadios = data;
        isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando radios: $e')),
      );
    }
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    var results = allRadios.where((radio) {
      final name = (radio['name'] ?? radio['station_name'] ?? radio['title'] ?? '')
          .toString()
          .toLowerCase();

      final city = (radio['city'] ?? '').toString().toLowerCase();
      final country = (radio['country'] ?? '').toString().toLowerCase();
      final description = (radio['description'] ?? '').toString().toLowerCase();

      return query.isEmpty ||
          name.contains(query) ||
          city.contains(query) ||
          country.contains(query) ||
          description.contains(query);
    }).toList();

    if (selectedMode == 'most_played') {
      results.sort((a, b) {
        final aCount = a['play_count'] is int
            ? a['play_count'] as int
            : int.tryParse(a['play_count']?.toString() ?? '0') ?? 0;
        final bCount = b['play_count'] is int
            ? b['play_count'] as int
            : int.tryParse(b['play_count']?.toString() ?? '0') ?? 0;
        return bCount.compareTo(aCount);
      });
    } else if (selectedMode == 'most_liked') {
      results.sort((a, b) {
        final aCount = a['likes_count'] is int
            ? a['likes_count'] as int
            : int.tryParse(a['likes_count']?.toString() ?? '0') ?? 0;
        final bCount = b['likes_count'] is int
            ? b['likes_count'] as int
            : int.tryParse(b['likes_count']?.toString() ?? '0') ?? 0;
        return bCount.compareTo(aCount);
      });
    }

    setState(() {
      filteredRadios = results;
    });
  }

  Future<void> _toggleLike(String radioId) async {
    try {
      await RadioService.toggleLike(radioId);
      await _loadRadios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en Me gusta: $e')),
      );
    }
  }

  void _cancelPlayCount() {
    _playCountTimer?.cancel();
    _playCountTimer = null;
    _countingRadioId = null;
  }

  void _schedulePlayCount(String radioId) {
    _cancelPlayCount();

    if (_alreadyCountedThisSession.contains(radioId)) {
      return;
    }

    _countingRadioId = radioId;

    _playCountTimer = Timer(const Duration(seconds: 90), () async {
      final currentRadioId = AudioPlayerService.currentRadioId;
      final stillPlaying = AudioPlayerService.isPlaying;

      if (stillPlaying &&
          currentRadioId == radioId &&
          !_alreadyCountedThisSession.contains(radioId)) {
        _alreadyCountedThisSession.add(radioId);
        await RadioService.registerPlay(radioId);
        await _loadRadios();
      }
    });
  }

  Future<void> _togglePlay(Map<String, dynamic> radio) async {
    final radioId = radio['id']?.toString() ?? '';
    final streamUrl =
    (radio['stream_url'] ?? radio['stream_link'] ?? radio['url'] ?? '')
        .toString();

    final radioName =
    (radio['name'] ?? radio['station_name'] ?? radio['title'] ?? 'Radio')
        .toString();

    if (radioId.isEmpty || streamUrl.isEmpty) return;

    try {
      final isSameRadio = AudioPlayerService.currentUrl == streamUrl;

      if (isSameRadio) {
        if (AudioPlayerService.isPlaying) {
          await AudioPlayerService.pause();
          _cancelPlayCount();
        } else {
          await AudioPlayerService.resume();
          _schedulePlayCount(radioId);
        }

        if (!mounted) return;
        setState(() {});
        return;
      }

      await AudioPlayerService.playRadio(
        radioId: radioId,
        url: streamUrl,
        title: radioName,
      );

      _schedulePlayCount(radioId);

      if (!mounted) return;
      setState(() {
        expandedRadioId = radioId;
      });
    } catch (e) {
      _cancelPlayCount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reproduciendo radio: $e')),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  Widget _miniHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.radio, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Radios cristianas online',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected = selectedMode == value;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) {
          setState(() {
            selectedMode = value;
          });
          _applyFilters();
        },
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _radioCard(Map<String, dynamic> radio) {
    final radioId = radio['id']?.toString() ?? '';
    final isExpanded = expandedRadioId == radioId;

    final streamUrl =
    (radio['stream_url'] ?? radio['stream_link'] ?? radio['url'] ?? '')
        .toString();

    final isPlaying =
        AudioPlayerService.currentUrl == streamUrl && AudioPlayerService.isPlaying;

    final logoUrl = (radio['logo_url'] ??
        radio['image_url'] ??
        radio['logo'] ??
        radio['station_logo'] ??
        '')
        .toString();

    final name =
    (radio['name'] ?? radio['station_name'] ?? radio['title'] ?? 'Radio')
        .toString();

    final city = (radio['city'] ?? '').toString();
    final country = (radio['country'] ?? '').toString();
    final description = (radio['description'] ?? '').toString();
    final website =
    (radio['website_url'] ?? radio['website'] ?? radio['link'] ?? '')
        .toString();

    final likesCount = radio['likes_count'] ?? 0;
    final likedByMe = radio['liked_by_me'] == true;
    final playCount = radio['play_count'] is int
        ? radio['play_count'] as int
        : int.tryParse(radio['play_count']?.toString() ?? '0') ?? 0;

    final location = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ].join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPlaying ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isPlaying
            ? Border.all(color: const Color(0xFF2E7D32), width: 1.4)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              setState(() {
                expandedRadioId = isExpanded ? null : radioId;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      image: logoUrl.isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(logoUrl),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: logoUrl.isEmpty
                        ? Icon(
                      isPlaying ? Icons.equalizer : Icons.radio,
                      color: isPlaying
                          ? Colors.white
                          : const Color(0xFF2E7D32),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.5,
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8E9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$playCount reproducciones',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$likesCount likes',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  if (website.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _openUrl(website),
                      icon: const Icon(Icons.language),
                      label: const Text('Web de la radio'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _togglePlay(radio),
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(isPlaying ? 'Pausar' : 'Reproducir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(46),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: () => _toggleLike(radioId),
                        icon: Icon(
                          likedByMe ? Icons.favorite : Icons.favorite_border,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                          likedByMe ? Colors.red : Colors.orange.shade100,
                          foregroundColor:
                          likedByMe ? Colors.white : Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AudioPlayerService.isPlayingNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              _miniHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar radio, ciudad o país',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _modeChip(
                      value: 'all',
                      label: 'Todas',
                      icon: Icons.radio_outlined,
                    ),
                    _modeChip(
                      value: 'most_played',
                      label: 'Más reproducida',
                      icon: Icons.graphic_eq,
                    ),
                    _modeChip(
                      value: 'most_liked',
                      label: 'Más likes',
                      icon: Icons.favorite_border,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredRadios.isEmpty
                    ? const Center(
                  child: Text('No se encontraron emisoras.'),
                )
                    : RefreshIndicator(
                  onRefresh: _loadRadios,
                  child: ListView.builder(
                    padding:
                    const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: filteredRadios.length,
                    itemBuilder: (context, index) =>
                        _radioCard(filteredRadios[index]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}