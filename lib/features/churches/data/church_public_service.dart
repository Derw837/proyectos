import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchPublicService {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>> getChurchStats(String churchId) async {
    final user = _client.auth.currentUser;

    final likesResponse = await _client
        .from('church_likes')
        .select('id, user_id')
        .eq('church_id', churchId);

    final membersResponse = await _client
        .from('church_memberships')
        .select('id, user_id')
        .eq('church_id', churchId);

    final likes = List<Map<String, dynamic>>.from(likesResponse);
    final members = List<Map<String, dynamic>>.from(membersResponse);

    return {
      'likes_count': likes.length,
      'members_count': members.length,
      'liked_by_me': user == null
          ? false
          : likes.any((like) => like['user_id'] == user.id),
      'member_by_me': user == null
          ? false
          : members.any((member) => member['user_id'] == user.id),
    };
  }

  static Future<void> toggleChurchLike(String churchId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión');
    }

    final existing = await _client
        .from('church_likes')
        .select()
        .eq('church_id', churchId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('church_likes')
          .delete()
          .eq('church_id', churchId)
          .eq('user_id', user.id);
    } else {
      await _client.from('church_likes').insert({
        'church_id': churchId,
        'user_id': user.id,
      });
    }
  }

  static Future<void> toggleMembership(String churchId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión');
    }

    final existing = await _client
        .from('church_memberships')
        .select()
        .eq('church_id', churchId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('church_memberships')
          .delete()
          .eq('church_id', churchId)
          .eq('user_id', user.id);
    } else {
      await _client.from('church_memberships').insert({
        'church_id': churchId,
        'user_id': user.id,
      });
    }
  }
}