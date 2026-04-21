import 'package:flutter/material.dart';

class TvSectionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const TvSectionRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if ((subtitle ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 146,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}