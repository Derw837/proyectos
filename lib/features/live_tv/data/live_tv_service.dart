import 'package:supabase_flutter/supabase_flutter.dart';

class LiveTvService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getActiveChannels() async {
    final response = await _client
        .from('live_tv_channels')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('is_featured', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static bool isYoutubeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final host = uri.host.toLowerCase();
    return host.contains('youtube.com') || host.contains('youtu.be');
  }

  static bool isM3u8Url(String url) {
    return url.toLowerCase().contains('.m3u8');
  }

  static bool isMp4Url(String url) {
    return url.toLowerCase().contains('.mp4');
  }

  static String detectSourceType(Map<String, dynamic> channel) {
    final sourceType = channel['source_type']?.toString().trim().toLowerCase() ?? '';
    final url = channel['stream_url']?.toString().trim() ?? '';

    if (sourceType.isNotEmpty) return sourceType;
    if (isYoutubeUrl(url)) return 'youtube';
    if (isM3u8Url(url)) return 'm3u8';
    if (isMp4Url(url)) return 'mp4';
    return 'external';
  }
}