import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchProfileVideosService {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getMyChurch() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    return await _client
        .from('churches')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
  }

  static Future<List<Map<String, dynamic>>> getMyVideos() async {
    final church = await getMyChurch();
    if (church == null) return [];

    final response = await _client
        .from('church_profile_videos')
        .select()
        .eq('church_id', church['id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getChurchVideos(String churchId) async {
    final response = await _client
        .from('church_profile_videos')
        .select()
        .eq('church_id', churchId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> createVideo({
    required String churchId,
    required String title,
    required String description,
    required String videoUrl,
    required String thumbnailUrl,
  }) async {
    await _client.from('church_profile_videos').insert({
      'church_id': churchId,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'is_active': true,
    });
  }

  static Future<void> deleteVideo(String videoId) async {
    await _client.from('church_profile_videos').delete().eq('id', videoId);
  }

  static String? extractYoutubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtube.com')) {
      if (uri.queryParameters['v'] != null &&
          uri.queryParameters['v']!.trim().isNotEmpty) {
        return uri.queryParameters['v'];
      }

      if (uri.pathSegments.contains('live') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }

      if (uri.pathSegments.contains('embed') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }

      if (uri.pathSegments.contains('shorts') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    }

    if (uri.host.contains('youtu.be')) {
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
    }

    return null;
  }

  static String buildThumbnailFromYoutubeUrl(String url) {
    final id = extractYoutubeId(url);
    if (id == null || id.isEmpty) return '';
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }
}