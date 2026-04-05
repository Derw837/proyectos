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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final church = await Supabase.instance.client
        .from('churches')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    final churchId = church?['id']?.toString();
    if (churchId == null || churchId.isEmpty) return [];

    final memberships = await Supabase.instance.client
        .from('church_memberships')
        .select('user_id, created_at')
        .eq('church_id', churchId)
        .order('created_at', ascending: false);

    final membershipRows = List<Map<String, dynamic>>.from(memberships);

    if (membershipRows.isEmpty) return [];

    final userIds = membershipRows
        .map((e) => e['user_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final profiles = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, country, city, sector')
        .inFilter('id', userIds);

    final profilesMap = <String, Map<String, dynamic>>{};
    for (final raw in profiles) {
      final profile = Map<String, dynamic>.from(raw);
      final id = profile['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        profilesMap[id] = profile;
      }
    }

    final result = <Map<String, dynamic>>[];

    for (final membership in membershipRows) {
      final memberUserId = membership['user_id']?.toString() ?? '';
      result.add({
        'profile': profilesMap[memberUserId],
        'membership': membership,
      });
    }

    return result;
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