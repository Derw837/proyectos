import 'package:flutter/material.dart';
import 'package:red_cristiana/features/live_tv/data/live_tv_service.dart';
import 'package:red_cristiana/features_tv/player/tv_live_player_screen.dart';
import 'package:red_cristiana/features_tv/widgets/tv_hero_banner.dart';
import 'package:red_cristiana/features_tv/widgets/tv_poster_card.dart';

class TvLiveScreen extends StatefulWidget {
  const TvLiveScreen({super.key});

  @override
  State<TvLiveScreen> createState() => _TvLiveScreenState();
}

class _TvLiveScreenState extends State<TvLiveScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = LiveTvService.getActiveChannels();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final channels = snapshot.data!;
        final hero = channels.isNotEmpty ? channels.first : null;

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = LiveTvService.getActiveChannels();
              });
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 30),
              children: [
                const Text(
                  'TV en vivo',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Canales activos para ver en pantalla grande. Luego aquí añadiremos guía EPG sin cambiar tu estructura actual.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 18),
                TvHeroBanner(
                  title: hero?['name']?.toString() ?? 'Red Cristiana TV',
                  description: hero?['description']?.toString().trim().isNotEmpty == true
                      ? hero!['description'].toString()
                      : 'Explora canales cristianos en vivo con una experiencia premium para televisor.',
                  imageUrl: hero?['thumbnail_url']?.toString() ??
                      hero?['logo_url']?.toString(),
                  category: 'TV en vivo',
                ),
                const SizedBox(height: 28),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: channels.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 1.9,
                  ),
                  itemBuilder: (context, index) {
                    final channel = channels[index];

                    final subtitle = [
                      channel['country']?.toString(),
                      channel['category']?.toString(),
                    ].where((e) => (e ?? '').trim().isNotEmpty).join(' • ');

                    return TvPosterCard(
                      title: channel['name']?.toString() ?? 'Canal',
                      subtitle: subtitle.isEmpty ? 'En vivo' : subtitle,
                      imageUrl: channel['thumbnail_url']?.toString() ??
                          channel['logo_url']?.toString(),
                      width: double.infinity,
                      height: 140,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TvLivePlayerScreen(channel: channel),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}