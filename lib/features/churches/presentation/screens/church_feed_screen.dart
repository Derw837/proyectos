import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';
import 'package:red_cristiana/features/home/presentation/screens/home_feed_screen.dart';

class ChurchFeedScreen extends StatelessWidget {
  const ChurchFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChurchHeaderShell(
      child: HomeFeedScreen(),
    );
  }
}