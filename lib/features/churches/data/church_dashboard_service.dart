import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchDashboardService {
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

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final church = await getMyChurch();
    if (church == null) {
      return {
        'church': null,
        'likes_count': 0,
        'members_count': 0,
      };
    }

    final churchId = church['id'].toString();

    final likesResponse = await _client
        .from('church_likes')
        .select('id')
        .eq('church_id', churchId);

    final membersResponse = await _client
        .from('church_memberships')
        .select('id')
        .eq('church_id', churchId);

    return {
      'church': church,
      'likes_count': (likesResponse as List).length,
      'members_count': (membersResponse as List).length,
    };
  }

  static Future<List<Map<String, dynamic>>> getMyMembers() async {
    final church = await getMyChurch();
    if (church == null) return [];

    final churchId = church['id'].toString();

    final memberships = await _client
        .from('church_memberships')
        .select('id, user_id, created_at')
        .eq('church_id', churchId)
        .order('created_at', ascending: false);

    final members = <Map<String, dynamic>>[];

    for (final item in memberships) {
      final membership = Map<String, dynamic>.from(item);
      final userId = membership['user_id']?.toString();

      if (userId == null || userId.isEmpty) continue;

      final profile = await _client
          .from('profiles')
          .select('id, full_name, country, city, sector')
          .eq('id', userId)
          .maybeSingle();

      members.add({
        'membership': membership,
        'profile': profile,
      });
    }

    return members;
  }

  static Future<void> updateSpiritualHelp({
    required String churchId,
    required String label,
    required String url,
  }) async {
    await _client.from('churches').update({
      'spiritual_help_label': label,
      'spiritual_help_url': url,
    }).eq('id', churchId);
  }
}