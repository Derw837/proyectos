import 'package:flutter/material.dart';
import 'package:red_cristiana/features/live_tv/data/live_tv_service.dart';
import 'package:red_cristiana/features/live_tv/presentation/screens/network_stream_player_screen.dart';
import 'package:red_cristiana/features/media/presentation/screens/app_video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:red_cristiana/core/ads/ad_service.dart';
import 'package:red_cristiana/core/ads/ad_units.dart';
import 'package:red_cristiana/core/utils/app_error_helper.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  bool isLoading = true;
  String? loadErrorMessage;
  List<Map<String, dynamic>> allChannels = [];
  List<Map<String, dynamic>> filteredChannels = [];
  String selectedCountry = 'todos';

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        loadErrorMessage = null;
      });
    }

    try {
      final data = await LiveTvService.getActiveChannels();

      if (!mounted) return;

      setState(() {
        allChannels = data;
        filteredChannels = data;
        isLoading = false;
        loadErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      final friendly = await AppErrorHelper.friendlyMessage(
        e,
        fallback: 'No pudimos cargar los canales de TV en este momento.',
      );

      setState(() {
        isLoading = false;
        loadErrorMessage = friendly;
      });
    }
  }

  void _filterByCountry(String country) {
    setState(() {
      selectedCountry = country;

      if (country == 'todos') {
        filteredChannels = allChannels;
      } else {
        filteredChannels = allChannels.where((channel) {
          final value = channel['country']?.toString().trim().toLowerCase() ?? '';
          return value == country.toLowerCase();
        }).toList();
      }
    });
  }

  Future<void> _openSupportVideoAndLaunchChannel() async {
    if (filteredChannels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay canales disponibles en este momento.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final shown = await AdService.showRewardedAd(
      adUnitId: AdUnits.rewardedTvSupport,
      onRewardEarned: () async {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🙏 Gracias por apoyar Red Cristiana'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NetworkStreamPlayerScreen(
              channels: filteredChannels,
              initialIndex: 0,
            ),
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

  Future<void> _openChannel(Map<String, dynamic> channel) async {
    final url = channel['stream_url']?.toString().trim() ?? '';
    final sourceType = LiveTvService.detectSourceType(channel);
    final title = channel['name']?.toString() ?? 'TV en vivo';
    final description = channel['description']?.toString() ?? '';

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este canal no tiene enlace disponible')),
      );
      return;
    }

    if (sourceType == 'youtube') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppVideoPlayerScreen(
            title: title,
            description: description,
            videoUrl: url,
          ),
        ),
      );
      return;
    }

    if (sourceType == 'm3u8' || sourceType == 'mp4') {
      final currentList = filteredChannels.isNotEmpty ? filteredChannels : allChannels;
      final index = currentList.indexWhere(
            (item) => item['id'].toString() == channel['id'].toString(),
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NetworkStreamPlayerScreen(
            channels: currentList,
            initialIndex: index < 0 ? 0 : index,
          ),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El enlace del canal no es válido')),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el canal')),
      );
    }
  }

  Widget _countryChip(String value, String label) {
    final isSelected = selectedCountry == value;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _filterByCountry(value),
      ),
    );
  }

  Widget _channelCard(Map<String, dynamic> channel) {
    final name = channel['name']?.toString() ?? '';
    final description = channel['description']?.toString() ?? '';
    final country = channel['country']?.toString() ?? 'Internacional';
    final logoUrl = channel['logo_url']?.toString() ?? '';
    final thumbnailUrl = channel['thumbnail_url']?.toString() ?? '';
    final sourceType = LiveTvService.detectSourceType(channel);

    String actionText = 'Abrir canal';
    if (sourceType == 'youtube') {
      actionText = 'Ver en la app';
    } else if (sourceType == 'm3u8' || sourceType == 'mp4') {
      actionText = 'Reproducir';
    }

    final previewImage = thumbnailUrl.isNotEmpty ? thumbnailUrl : logoUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openChannel(channel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 88,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: previewImage.isNotEmpty
                  ? Image.network(
                previewImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.live_tv,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              )
                  : const Center(
                child: Icon(
                  Icons.live_tv,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'EN VIVO',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            country,
                            style: const TextStyle(
                              color: Color(0xFF0D47A1),
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Expanded(
                        child: Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 11.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            actionText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 18),
            Text(
              loadErrorMessage ??
                  'No pudimos cargar los canales de TV en este momento.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadChannels,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _availableCountries() {
    final values = allChannels
        .map((e) => e['country']?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    values.sort();
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final countries = _availableCountries();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        children: [
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _countryChip('todos', 'Todos'),
                ...countries.map((country) => _countryChip(country, country)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : loadErrorMessage != null && allChannels.isEmpty
                    ? _errorState()
                    : filteredChannels.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay canales en vivo disponibles todavía.',
                            ),
                          )
                        : RefreshIndicator(
              onRefresh: _loadChannels,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredChannels.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1B5E20),
                            Color(0xFF2E7D32),
                          ],
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
                        borderRadius: BorderRadius.circular(18),
                        onTap: _openSupportVideoAndLaunchChannel,
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Canal de apoyo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mira un video corto y luego entra directamente a nuestra señal en vivo.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.92),
                                      fontSize: 12.8,
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
                                      'Ver video y entrar a TV',
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

                  final realIndex = index - 1;
                  return _channelCard(filteredChannels[realIndex]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}