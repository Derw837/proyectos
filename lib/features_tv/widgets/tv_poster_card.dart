import 'package:flutter/material.dart';
import 'package:red_cristiana/features_tv/widgets/tv_pressable.dart';

class TvPosterCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const TvPosterCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.width = 220,
    this.height = 130,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = imageUrl?.trim();
    final hasImage = image != null && image.isNotEmpty;

    return TvPressable(
      onPressed: onTap ?? () {},
      builder: (context, focused) {
        return AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: focused ? 1.05 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: width,
            height: height,
            margin: const EdgeInsets.only(right: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: focused
                    ? const Color(0xFF4FC3F7)
                    : const Color(0x20FFFFFF),
                width: focused ? 2.2 : 1,
              ),
              boxShadow: focused
                  ? [
                BoxShadow(
                  color: const Color(0xFF4FC3F7).withOpacity(0.28),
                  blurRadius: 26,
                  spreadRadius: 3,
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
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
                        Color(0x05000000),
                        Color(0xAA000000),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if ((subtitle ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF132238),
            Color(0xFF0C1420),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          size: 42,
          color: Colors.white70,
        ),
      ),
    );
  }
}