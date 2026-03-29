import 'package:supabase_flutter/supabase_flutter.dart';

class RadioService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getActiveRadios() async {
    final user = _client.auth.currentUser;

    final response = await _client
        .from('radio_stations')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final radios = List<Map<String, dynamic>>.from(response);

    for (final radio in radios) {
      final radioId = radio['id']?.toString() ?? '';
      if (radioId.isEmpty) continue;

      final likesResponse = await _client
          .from('radio_likes')
          .select('id, user_id')
          .eq('radio_id', radioId);

      final likes = List<Map<String, dynamic>>.from(likesResponse);

      radio['likes_count'] = likes.length;
      radio['liked_by_me'] = user == null
          ? false
          : likes.any((item) => item['user_id'] == user.id);
    }

    if (user != null) {
      radios.sort((a, b) {
        final aLiked = a['liked_by_me'] == true ? 1 : 0;
        final bLiked = b['liked_by_me'] == true ? 1 : 0;

        if (aLiked != bLiked) {
          return bLiked.compareTo(aLiked);
        }

        return 0;
      });
    }

    return radios;
  }

  static Future<void> toggleLike(String radioId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión');
    }

    final existing = await _client
        .from('radio_likes')
        .select()
        .eq('radio_id', radioId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('radio_likes')
          .delete()
          .eq('radio_id', radioId)
          .eq('user_id', user.id);
    } else {
      await _client.from('radio_likes').insert({
        'radio_id': radioId,
        'user_id': user.id,
      });
    }
  }

  static Future<void> registerPlay(String radioId) async {
    final current = await _client
        .from('radio_stations')
        .select('play_count')
        .eq('id', radioId)
        .maybeSingle();

    final currentCount = current?['play_count'] is int
        ? current!['play_count'] as int
        : int.tryParse(current?['play_count']?.toString() ?? '0') ?? 0;

    await _client.from('radio_stations').update({
      'play_count': currentCount + 1,
    }).eq('id', radioId);
  }
}