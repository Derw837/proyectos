import 'package:supabase_flutter/supabase_flutter.dart';

class MediaVideoService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getActiveVideos() async {
    final response = await _client
        .from('media_videos')
        .select()
        .eq('is_active', true)
        .order('is_featured', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}