import 'package:flutter/material.dart';
import 'package:red_cristiana/features_tv/player/tv_video_player_screen.dart';

class TvVideoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const TvVideoDetailScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? 'Contenido';
    final description = (item['description']?.toString().trim().isNotEmpty ?? false)
        ? item['description'].toString()
        : 'Contenido disponible en Red Cristiana TV.';
    final imageUrl = item['thumbnail_url']?.toString();
    final category = item['category']?.toString() ?? 'video';

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 30),
          children: [
            Row(
              children: [
                _TvDetailButton(
                  label: 'Volver',
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              height: 380,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  else
                    _fallback(),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xC0000000),
                          Color(0x85000000),
                          Color(0xE0060A12),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(34),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _prettyCategory(category),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            _TvDetailButton(
                              label: 'Reproducir',
                              icon: Icons.play_arrow_rounded,
                              filled: true,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TvVideoPlayerScreen(
                                      title: title,
                                      description: description,
                                      videoUrl: item['video_url']?.toString() ?? '',
                                    ),
                                  ),
                                );
                              },
                            ),
                            _TvDetailButton(
                              label: 'Apoyar misión',
                              icon: Icons.favorite_rounded,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Luego conectaremos aquí la pantalla de apoyo/QR.'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
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

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF15304F),
            Color(0xFF0A121D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          size: 80,
          color: Colors.white70,
        ),
      ),
    );
  }

  String _prettyCategory(String raw) {
    switch (raw.toLowerCase()) {
      case 'pelicula':
        return 'Película';
      case 'predicacion':
        return 'Predicación';
      case 'testimonio':
        return 'Testimonio';
      case 'serie':
        return 'Serie';
      default:
        return raw;
    }
  }
}

class _TvDetailButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _TvDetailButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_TvDetailButton> createState() => _TvDetailButtonState();
}

class _TvDetailButtonState extends State<_TvDetailButton> {
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
                : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _focused
                  ? const Color(0xFF4FC3F7)
                  : Colors.white.withValues(alpha: 0.20),
              width: _focused ? 2 : 1,
            ),
            boxShadow: _focused
                ? [
              BoxShadow(
                color: const Color(0xFF4FC3F7).withValues(alpha: 0.22),
                blurRadius: 18,
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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