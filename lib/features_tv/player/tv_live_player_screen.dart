import 'package:flutter/material.dart';
import 'package:red_cristiana/features_tv/player/tv_video_player_screen.dart';

class TvLivePlayerScreen extends StatelessWidget {
  final Map<String, dynamic> channel;

  const TvLivePlayerScreen({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    final name = channel['name']?.toString() ?? 'Canal';
    final description = channel['description']?.toString() ?? '';
    final streamUrl = channel['stream_url']?.toString() ?? '';

    return TvVideoPlayerScreen(
      title: name,
      description: description,
      videoUrl: streamUrl,
    );
  }
}