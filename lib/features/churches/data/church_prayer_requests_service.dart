import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchPrayerRequestsService {
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

  static Future<List<Map<String, dynamic>>> getPrayerRequestsForMyChurch() async {
    final church = await getMyChurch();
    if (church == null) return [];

    final churchId = church['id']?.toString() ?? '';
    if (churchId.isEmpty) return [];

    final requests = await _client
        .from('prayer_church_requests')
        .select('''
          id,
          prayer_request_id,
          church_id,
          requested_by_user_id,
          created_at
        ''')
        .eq('church_id', churchId)
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(requests);

    if (rows.isEmpty) return [];

    final prayerIds = rows
        .map((e) => e['prayer_request_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final requesterIds = rows
        .map((e) => e['requested_by_user_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final prayerMap = <String, Map<String, dynamic>>{};
    if (prayerIds.isNotEmpty) {
      final prayers = await _client
          .from('prayer_requests')
          .select('id, user_id, full_name, is_for_me, category, status, created_at')
          .inFilter('id', prayerIds);

      for (final raw in prayers) {
        final prayer = Map<String, dynamic>.from(raw);
        final id = prayer['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          prayerMap[id] = prayer;
        }
      }
    }

    final prayerAuthorIds = prayerMap.values
        .map((e) => e['user_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final allProfileIds = {...requesterIds, ...prayerAuthorIds}.toList();

    final profilesMap = <String, Map<String, dynamic>>{};
    if (allProfileIds.isNotEmpty) {
      final profiles = await _client
          .from('profiles')
          .select('id, full_name, country, city, sector')
          .inFilter('id', allProfileIds);

      for (final raw in profiles) {
        final profile = Map<String, dynamic>.from(raw);
        final id = profile['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          profilesMap[id] = profile;
        }
      }
    }

    final members = await _client
        .from('church_memberships')
        .select('user_id')
        .eq('church_id', churchId);

    final memberIds = members
        .map((e) => e['user_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet();

    final supports = await _client
        .from('prayer_church_supports')
        .select('id, prayer_request_id, church_id')
        .eq('church_id', churchId);

    final supportedPrayerIds = supports
        .map((e) => e['prayer_request_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet();

    final requestCountByPrayer = <String, int>{};
    for (final row in rows) {
      final prayerId = row['prayer_request_id']?.toString() ?? '';
      if (prayerId.isEmpty) continue;
      requestCountByPrayer[prayerId] = (requestCountByPrayer[prayerId] ?? 0) + 1;
    }

    final seenPrayerIds = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final row in rows) {
      final prayerId = row['prayer_request_id']?.toString() ?? '';
      if (prayerId.isEmpty || seenPrayerIds.contains(prayerId)) continue;

      final prayer = prayerMap[prayerId];
      if (prayer == null) continue;

      final prayerUserId = prayer['user_id']?.toString() ?? '';
      final requesterId = row['requested_by_user_id']?.toString() ?? '';

      final prayerAuthorProfile = profilesMap[prayerUserId];
      final requesterProfile = profilesMap[requesterId];

      final prayerAuthorName =
      prayerAuthorProfile?['full_name']?.toString().trim().isNotEmpty == true
          ? prayerAuthorProfile!['full_name'].toString().trim()
          : 'Un usuario';

      final fullNameThird = prayer['full_name']?.toString().trim() ?? '';

      result.add({
        'prayer_request_id': prayerId,
        'created_at': prayer['created_at'],
        'category': prayer['category'],
        'is_for_me': prayer['is_for_me'] == true,
        'full_name': fullNameThird,
        'prayer_author_name': prayerAuthorName,
        'requested_by_user_id': requesterId,
        'requested_by_profile': requesterProfile,
        'is_member_of_my_church': memberIds.contains(prayerUserId),
        'requested_count': requestCountByPrayer[prayerId] ?? 1,
        'supported_by_my_church': supportedPrayerIds.contains(prayerId),
      });

      seenPrayerIds.add(prayerId);
    }

    result.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
      final bDate =
          DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return result;
  }

  static Future<void> toggleChurchPrayerSupport(String prayerRequestId) async {
    final church = await getMyChurch();
    if (church == null) {
      throw Exception('No se encontró la iglesia asociada a esta cuenta');
    }

    final churchId = church['id']?.toString() ?? '';
    if (churchId.isEmpty) {
      throw Exception('No se encontró el ID de la iglesia');
    }

    final existing = await _client
        .from('prayer_church_supports')
        .select()
        .eq('prayer_request_id', prayerRequestId)
        .eq('church_id', churchId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('prayer_church_supports')
          .delete()
          .eq('prayer_request_id', prayerRequestId)
          .eq('church_id', churchId);
    } else {
      await _client.from('prayer_church_supports').insert({
        'prayer_request_id': prayerRequestId,
        'church_id': churchId,
      });
    }
  }

  static String categoryLabel(String value) {
    switch (value) {
      case 'salud':
        return 'Salud';
      case 'matrimonio':
        return 'Matrimonio';
      case 'familia':
        return 'Familia';
      case 'hijos':
        return 'Hijos';
      case 'trabajo':
        return 'Trabajo';
      case 'finanzas':
        return 'Finanzas';
      case 'proteccion':
        return 'Protección';
      case 'estudios':
        return 'Estudios';
      case 'direccion':
        return 'Dirección de Dios';
      case 'paz':
        return 'Paz';
      case 'sanidad_emocional':
        return 'Sanidad emocional';
      case 'fortaleza_espiritual':
        return 'Fortaleza espiritual';
      case 'liberacion':
        return 'Liberación';
      default:
        return 'Petición';
    }
  }
}