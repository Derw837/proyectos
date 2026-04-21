import 'package:flutter/material.dart';

class TvHeroBanner extends StatelessWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final String? category;

  const TvHeroBanner({
    super.key,
    required this.title,
    required this.description,
    this.imageUrl,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final image = imageUrl?.trim();
    final hasImage = image != null && image.isNotEmpty;

    return Container(
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x22FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          else
            _fallback(),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xB0000000),
                  Color(0x70000000),
                  Color(0xD0060A12),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(38, 32, 38, 32),
            child: Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if ((category ?? '').trim().isNotEmpty)
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
                              category!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 42,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
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
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _HeroButton(
                              icon: Icons.play_arrow_rounded,
                              label: 'Seguir explorando',
                              filled: true,
                              onTap: () {},
                            ),
                            const SizedBox(width: 14),
                            _HeroButton(
                              icon: Icons.favorite_rounded,
                              label: 'Apoyar la misión',
                              filled: false,
                              onTap: () {},
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
        ],
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
    );
  }
}

class _HeroButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _HeroButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
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
                : Colors.white.withValues(alpha: 0.12),
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