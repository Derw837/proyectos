import 'package:flutter/material.dart';
import 'package:red_cristiana/features_tv/widgets/tv_placeholder.dart';

class TvSupportScreen extends StatelessWidget {
  const TvSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TvPlaceholder(
      title: 'Apóyanos',
      subtitle: 'Aquí pondremos el QR grande para donar desde el celular.',
      icon: Icons.favorite_rounded,
    );
  }
}