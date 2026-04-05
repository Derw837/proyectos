import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchMemberNotificationsService {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getMyChurch() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final church = await _client
        .from('churches')
        .select('id, church_name')
        .eq('user_id', user.id)
        .maybeSingle();

    if (church == null) return null;
    return Map<String, dynamic>.from(church);
  }

  static Future<int> sendNotificationToMyMembers({
    required String title,
    required String message,
  }) async {
    final church = await getMyChurch();
    if (church == null) {
      throw Exception('No se encontró la iglesia asociada a esta cuenta');
    }

    final churchId = church['id']?.toString() ?? '';
    if (churchId.isEmpty) {
      throw Exception('No se encontró el ID de la iglesia');
    }

    final memberships = await _client
        .from('church_memberships')
        .select('user_id')
        .eq('church_id', churchId);

    final memberUserIds = memberships
        .map((row) => row['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (memberUserIds.isEmpty) {
      return 0;
    }

    final rows = memberUserIds
        .map((userId) => {
      'user_id': userId,
      'church_id': churchId,
      'title': title.trim(),
      'message': message.trim(),
      'type': 'post', // temporal, hasta ampliar el CHECK
      'related_id': null,
      'is_read': false,
    })
        .toList();

    await _client.from('user_notifications').insert(rows);

    return rows.length;
  }
}