import 'package:flutter/material.dart';
import 'package:red_cristiana/features/media/presentation/screens/app_video_player_screen.dart';

class VideoNotificationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> video;

  const VideoNotificationDetailScreen({
    super.key,
    required this.video,
  });

  @override
  Widget build(BuildContext context) {
    final title = video['title']?.toString() ?? '';
    final description = video['description']?.toString() ?? '';
    final videoUrl = video['video_url']?.toString() ?? '';

    return AppVideoPlayerScreen(
      title: title,
      description: description,
      videoUrl: videoUrl,
    );
  }
}