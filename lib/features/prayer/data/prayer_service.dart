import 'package:supabase_flutter/supabase_flutter.dart';

class PrayerService {
  static final _client = Supabase.instance.client;

  static Future<void> createPrayerRequest({
    required bool isForMe,
    required String targetName,
    required String category,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión');

    final membership = await _client
        .from('church_memberships')
        .select('church_id')
        .eq('user_id', user.id)
        .maybeSingle();

    final originChurchId = membership?['church_id']?.toString();

    final insertResponse = await _client
        .from('prayer_requests')
        .insert({
      'user_id': user.id,
      'is_for_me': isForMe,
      'full_name': isForMe ? null : targetName.trim(),
      'category': category,
      'status': 'active',
      'origin_church_id': originChurchId,
    })
        .select('id')
        .single();

    final prayerRequestId = insertResponse['id']?.toString();
    if (prayerRequestId == null || prayerRequestId.isEmpty) {
      throw Exception('No se pudo crear la petición');
    }

    await _notifyChurchMembersAboutPrayer(
      prayerRequestId: prayerRequestId,
      userId: user.id,
      isForMe: isForMe,
      targetName: targetName.trim(),
      category: category,
    );
  }

  static Future<void> createChurchPrayerRequest({
    required String messageText,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión');

    final church = await _client
        .from('churches')
        .select('id, church_name')
        .eq('user_id', user.id)
        .maybeSingle();

    if (church == null) {
      throw Exception('No se encontró la iglesia asociada a esta cuenta');
    }

    final churchId = church['id']?.toString() ?? '';
    final churchName = church['church_name']?.toString().trim().isNotEmpty == true
        ? church['church_name'].toString().trim()
        : 'Mi iglesia';

    final insertResponse = await _client
        .from('prayer_requests')
        .insert({
      'user_id': user.id,
      'is_for_me': true,
      'full_name': null,
      'category': 'iglesia',
      'status': 'active',
      'origin_church_id': churchId,
      'message_text': messageText.trim(),
      'author_type': 'church',
    })
        .select('id')
        .single();

    final prayerRequestId = insertResponse['id']?.toString();
    if (prayerRequestId == null || prayerRequestId.isEmpty) {
      throw Exception('No se pudo crear la petición');
    }

    final memberRows = await _client
        .from('church_memberships')
        .select('user_id')
        .eq('church_id', churchId);

    final memberUserIds = memberRows
        .map((e) => e['user_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty && e != user.id)
        .toSet()
        .toList();

    if (memberUserIds.isEmpty) return;

    final rows = memberUserIds.map((targetUserId) {
      return {
        'user_id': targetUserId,
        'church_id': churchId,
        'related_id': prayerRequestId,
        'type': 'prayer_request',
        'title': 'Nueva oración de $churchName',
        'message': messageText.trim(),
        'is_read': false,
      };
    }).toList();

    await _client.from('user_notifications').insert(rows);
  }

  static Future<void> _notifyChurchMembersAboutPrayer({
    required String prayerRequestId,
    required String userId,
    required bool isForMe,
    required String targetName,
    required String category,
  }) async {
    final profile = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();

    final publisherName =
    profile?['full_name']?.toString().trim().isNotEmpty == true
        ? profile!['full_name'].toString().trim()
        : 'Un miembro';

    final membership = await _client
        .from('church_memberships')
        .select('church_id')
        .eq('user_id', userId)
        .maybeSingle();

    final churchId = membership?['church_id']?.toString();
    if (churchId == null || churchId.isEmpty) return;

    // Crear la solicitud automática a la iglesia de origen
    final existingChurchRequest = await _client
        .from('prayer_church_requests')
        .select('id')
        .eq('prayer_request_id', prayerRequestId)
        .eq('church_id', churchId)
        .maybeSingle();

    if (existingChurchRequest == null) {
      await _client.from('prayer_church_requests').insert({
        'prayer_request_id': prayerRequestId,
        'church_id': churchId,
        'requested_by_user_id': userId,
      });
    }

    final memberRows = await _client
        .from('church_memberships')
        .select('user_id')
        .eq('church_id', churchId);

    final memberUserIds = memberRows
        .map((e) => e['user_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty && e != userId)
        .toSet()
        .toList();

    final churchRow = await _client
        .from('churches')
        .select('user_id, church_name')
        .eq('id', churchId)
        .maybeSingle();

    final churchOwnerUserId = churchRow?['user_id']?.toString();
    final churchName = churchRow?['church_name']?.toString() ?? 'tu iglesia';

    final prayerText = isForMe
        ? '$publisherName publicó una petición de oración por ${categoryLabel(category)}.'
        : '$publisherName publicó una petición de oración por $targetName por ${categoryLabel(category)}.';

    // OJO: excluimos al owner, porque la iglesia ya recibe por trigger
    final targetUserIds = memberUserIds
        .where((id) => id != churchOwnerUserId)
        .toSet()
        .toList();

    if (targetUserIds.isEmpty) return;

    final rows = targetUserIds
        .map((targetUserId) => {
      'user_id': targetUserId,
      'title': 'Nueva petición de oración',
      'message': '$prayerText Iglesia: $churchName',
      'type': 'prayer_request',
      'related_id': prayerRequestId,
      'is_read': false,
    })
        .toList();

    await _client.from('user_notifications').insert(rows);
  }

  static Future<List<Map<String, dynamic>>> getPrayerRequests() async {
    final user = _client.auth.currentUser;

    String? myChurchId;
    String? myRole;

    if (user != null) {
      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      myRole = profile?['role']?.toString();

      if (myRole == 'church') {
        final churchRow = await _client
            .from('churches')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();

        myChurchId = churchRow?['id']?.toString();
      } else {
        final membership = await _client
            .from('church_memberships')
            .select('church_id')
            .eq('user_id', user.id)
            .maybeSingle();

        myChurchId = membership?['church_id']?.toString();
      }
    }

    final requestsResponse = await _client
        .from('prayer_requests')
        .select('id, user_id, full_name, is_for_me, category, status, created_at, origin_church_id')
        .eq('status', 'active')
        .order('created_at', ascending: false);

    final requests = List<Map<String, dynamic>>.from(requestsResponse);

    final userIds = requests
        .map((e) => e['user_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final profilesMap = <String, Map<String, dynamic>>{};
    if (userIds.isNotEmpty) {
      final profilesResponse = await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', userIds);

      for (final raw in profilesResponse) {
        final profile = Map<String, dynamic>.from(raw);
        final id = profile['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          profilesMap[id] = profile;
        }
      }
    }

    final requestIds = requests
        .map((e) => e['id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final userSupportsMap = <String, List<Map<String, dynamic>>>{};
    final churchSupportsMap = <String, List<Map<String, dynamic>>>{};
    final churchRequestsMap = <String, List<Map<String, dynamic>>>{};

    if (requestIds.isNotEmpty) {
      final userSupportsResponse = await _client
          .from('prayer_user_supports')
          .select('id, prayer_request_id, user_id')
          .inFilter('prayer_request_id', requestIds);

      for (final raw in userSupportsResponse) {
        final item = Map<String, dynamic>.from(raw);
        final prayerId = item['prayer_request_id']?.toString() ?? '';
        if (prayerId.isEmpty) continue;
        userSupportsMap.putIfAbsent(prayerId, () => []).add(item);
      }

      final churchSupportsResponse = await _client
          .from('prayer_church_supports')
          .select('id, prayer_request_id, church_id')
          .inFilter('prayer_request_id', requestIds);

      for (final raw in churchSupportsResponse) {
        final item = Map<String, dynamic>.from(raw);
        final prayerId = item['prayer_request_id']?.toString() ?? '';
        if (prayerId.isEmpty) continue;
        churchSupportsMap.putIfAbsent(prayerId, () => []).add(item);
      }

      final churchRequestsResponse = await _client
          .from('prayer_church_requests')
          .select('id, prayer_request_id, church_id, requested_by_user_id')
          .inFilter('prayer_request_id', requestIds);

      for (final raw in churchRequestsResponse) {
        final item = Map<String, dynamic>.from(raw);
        final prayerId = item['prayer_request_id']?.toString() ?? '';
        if (prayerId.isEmpty) continue;
        churchRequestsMap.putIfAbsent(prayerId, () => []).add(item);
      }
    }

    final result = <Map<String, dynamic>>[];

    for (final request in requests) {
      final requestId = request['id']?.toString() ?? '';
      final requestUserId = request['user_id']?.toString() ?? '';
      final supportsUsers = userSupportsMap[requestId] ?? [];
      final supportsChurches = churchSupportsMap[requestId] ?? [];
      final churchRequests = churchRequestsMap[requestId] ?? [];
      final profile = profilesMap[requestUserId];
      final originChurchId = request['origin_church_id']?.toString() ?? '';

      bool supportedByMyChurch = false;
      bool requestedMyChurch = false;
      int myChurchRequestCount = 0;
      bool belongsToMyChurch = false;
      bool canRequestMyChurch = false;
      bool canChurchSupportDirectly = false;

      if (myChurchId != null && myChurchId.isNotEmpty) {
        belongsToMyChurch = originChurchId.isNotEmpty && originChurchId == myChurchId;

        supportedByMyChurch =
            supportsChurches.any((e) => e['church_id'] == myChurchId);

        requestedMyChurch =
            churchRequests.any((e) => e['church_id'] == myChurchId);

        myChurchRequestCount =
            churchRequests.where((e) => e['church_id'] == myChurchId).length;

        canRequestMyChurch = !belongsToMyChurch &&
            !supportedByMyChurch &&
            !requestedMyChurch &&
            myRole != 'church';
      }

      if (myChurchId != null && myChurchId.isNotEmpty && myRole == 'church') {
        canChurchSupportDirectly = !supportedByMyChurch;
      }

      result.add({
        ...request,
        'profile': profile,
        'user_support_count': supportsUsers.length,
        'church_support_count': supportsChurches.length,
        'supported_by_me': user == null
            ? false
            : supportsUsers.any((e) => e['user_id'] == user.id),
        'supported_by_my_church': supportedByMyChurch,
        'my_church_id': myChurchId,
        'requested_my_church': requestedMyChurch,
        'my_church_request_count': myChurchRequestCount,
        'is_church_account': myRole == 'church',
        'origin_church_id': originChurchId,
        'belongs_to_my_church': belongsToMyChurch,
        'can_request_my_church': canRequestMyChurch,
        'can_church_support_directly': canChurchSupportDirectly,
      });
    }

    return result;
  }

  static Future<void> toggleUserSupport(String prayerRequestId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión');

    final existing = await _client
        .from('prayer_user_supports')
        .select()
        .eq('prayer_request_id', prayerRequestId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('prayer_user_supports')
          .delete()
          .eq('prayer_request_id', prayerRequestId)
          .eq('user_id', user.id);
    } else {
      await _client.from('prayer_user_supports').insert({
        'prayer_request_id': prayerRequestId,
        'user_id': user.id,
      });
    }
  }

  static Future<void> toggleChurchSupport(String prayerRequestId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión');

    final profile = await _client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    final role = profile?['role']?.toString() ?? '';
    if (role != 'church') {
      throw Exception('Solo las cuentas iglesia pueden marcar esta opción');
    }

    final church = await _client
        .from('churches')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    final churchId = church?['id']?.toString();
    if (churchId == null || churchId.isEmpty) {
      throw Exception('No se encontró la iglesia asociada a esta cuenta');
    }

    final existing = await _client
        .from('prayer_church_supports')
        .select('id')
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

  static Future<void> requestMyChurchPrayer(String prayerRequestId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión');

    final membership = await _client
        .from('church_memberships')
        .select('church_id')
        .eq('user_id', user.id)
        .maybeSingle();

    final churchId = membership?['church_id']?.toString();
    if (churchId == null || churchId.isEmpty) {
      throw Exception('No perteneces a una iglesia');
    }

    final prayer = await _client
        .from('prayer_requests')
        .select('id, origin_church_id')
        .eq('id', prayerRequestId)
        .maybeSingle();

    if (prayer == null) {
      throw Exception('La petición ya no existe');
    }

    final originChurchId = prayer['origin_church_id']?.toString() ?? '';

    if (originChurchId.isNotEmpty && originChurchId == churchId) {
      throw Exception(
        'Esta petición ya fue enviada automáticamente a tu iglesia',
      );
    }

    final alreadySupporting = await _client
        .from('prayer_church_supports')
        .select('id')
        .eq('prayer_request_id', prayerRequestId)
        .eq('church_id', churchId)
        .maybeSingle();

    if (alreadySupporting != null) {
      return;
    }

    final existingChurchRequest = await _client
        .from('prayer_church_requests')
        .select('id')
        .eq('prayer_request_id', prayerRequestId)
        .eq('church_id', churchId)
        .maybeSingle();

    if (existingChurchRequest != null) {
      return;
    }

    await _client.from('prayer_church_requests').insert({
      'prayer_request_id': prayerRequestId,
      'church_id': churchId,
      'requested_by_user_id': user.id,
    });
  }

  static Future<List<Map<String, dynamic>>> getPrayerRequestsPage({
    String? olderThan,
    int limit = 20,
  }) async {
    final user = _client.auth.currentUser;

    String? myChurchId;
    String? myRole;

    if (user != null) {
      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      myRole = profile?['role']?.toString();

      if (myRole == 'church') {
        final churchRow = await _client
            .from('churches')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();

        myChurchId = churchRow?['id']?.toString();
      } else {
        final membership = await _client
            .from('church_memberships')
            .select('church_id')
            .eq('user_id', user.id)
            .maybeSingle();

        myChurchId = membership?['church_id']?.toString();
      }
    }

    final baseQuery = _client
        .from('prayer_requests')
        .select(
      'id, user_id, full_name, is_for_me, category, status, created_at, origin_church_id, message_text, author_type',
    )
        .eq('status', 'active');

    final requestsResponse = olderThan != null && olderThan.isNotEmpty
        ? await baseQuery
        .lt('created_at', olderThan)
        .order('created_at', ascending: false)
        .limit(limit)
        : await baseQuery
        .order('created_at', ascending: false)
        .limit(limit);

    final requests = List<Map<String, dynamic>>.from(requestsResponse);

    final userIds = requests
        .map((e) => e['user_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final profilesMap = <String, Map<String, dynamic>>{};
    if (userIds.isNotEmpty) {
      final profilesResponse = await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', userIds);

      for (final raw in profilesResponse) {
        final profile = Map<String, dynamic>.from(raw);
        final id = profile['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          profilesMap[id] = profile;
        }
      }
    }

    final requestIds = requests
        .map((e) => e['id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final userSupportsMap = <String, List<Map<String, dynamic>>>{};
    final churchSupportsMap = <String, List<Map<String, dynamic>>>{};
    final churchRequestsMap = <String, List<Map<String, dynamic>>>{};

    if (requestIds.isNotEmpty) {
      final userSupportsResponse = await _client
          .from('prayer_user_supports')
          .select('id, prayer_request_id, user_id')
          .inFilter('prayer_request_id', requestIds);

      for (final raw in userSupportsResponse) {
        final item = Map<String, dynamic>.from(raw);
        final prayerId = item['prayer_request_id']?.toString() ?? '';
        if (prayerId.isEmpty) continue;
        userSupportsMap.putIfAbsent(prayerId, () => []).add(item);
      }

      final churchSupportsResponse = await _client
          .from('prayer_church_supports')
          .select('id, prayer_request_id, church_id')
          .inFilter('prayer_request_id', requestIds);

      for (final raw in churchSupportsResponse) {
        final item = Map<String, dynamic>.from(raw);
        final prayerId = item['prayer_request_id']?.toString() ?? '';
        if (prayerId.isEmpty) continue;
        churchSupportsMap.putIfAbsent(prayerId, () => []).add(item);
      }

      final churchRequestsResponse = await _client
          .from('prayer_church_requests')
          .select('id, prayer_request_id, church_id, requested_by_user_id')
          .inFilter('prayer_request_id', requestIds);

      for (final raw in churchRequestsResponse) {
        final item = Map<String, dynamic>.from(raw);
        final prayerId = item['prayer_request_id']?.toString() ?? '';
        if (prayerId.isEmpty) continue;
        churchRequestsMap.putIfAbsent(prayerId, () => []).add(item);
      }
    }

    final result = <Map<String, dynamic>>[];

    for (final request in requests) {
      final requestId = request['id']?.toString() ?? '';
      final requestUserId = request['user_id']?.toString() ?? '';
      final supportsUsers = userSupportsMap[requestId] ?? [];
      final supportsChurches = churchSupportsMap[requestId] ?? [];
      final churchRequests = churchRequestsMap[requestId] ?? [];
      final profile = profilesMap[requestUserId];
      final originChurchId = request['origin_church_id']?.toString() ?? '';

      bool supportedByMyChurch = false;
      bool requestedMyChurch = false;
      int myChurchRequestCount = 0;
      bool belongsToMyChurch = false;
      bool canRequestMyChurch = false;
      bool canChurchSupportDirectly = false;


      if (myChurchId != null && myChurchId.isNotEmpty) {
        belongsToMyChurch = originChurchId.isNotEmpty && originChurchId == myChurchId;

        supportedByMyChurch =
            supportsChurches.any((e) => e['church_id'] == myChurchId);

        requestedMyChurch =
            churchRequests.any((e) => e['church_id'] == myChurchId);

        myChurchRequestCount =
            churchRequests.where((e) => e['church_id'] == myChurchId).length;

        canRequestMyChurch = !belongsToMyChurch &&
            !supportedByMyChurch &&
            !requestedMyChurch &&
            myRole != 'church';
      }

      if (myChurchId != null && myChurchId.isNotEmpty && myRole == 'church') {
        canChurchSupportDirectly = !supportedByMyChurch;
      }

      result.add({
        ...request,
        'profile': profile,
        'user_support_count': supportsUsers.length,
        'church_support_count': supportsChurches.length,
        'supported_by_me': user == null
            ? false
            : supportsUsers.any((e) => e['user_id'] == user.id),
        'supported_by_my_church': supportedByMyChurch,
        'my_church_id': myChurchId,
        'requested_my_church': requestedMyChurch,
        'my_church_request_count': myChurchRequestCount,
        'is_church_account': myRole == 'church',
        'origin_church_id': originChurchId,
        'belongs_to_my_church': belongsToMyChurch,
        'can_request_my_church': canRequestMyChurch,
        'can_church_support_directly': canChurchSupportDirectly,
      });
    }

    return result;
  }

  static Future<void> deletePrayerRequest(String prayerRequestId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión');

    final prayer = await _client
        .from('prayer_requests')
        .select('id, user_id')
        .eq('id', prayerRequestId)
        .maybeSingle();

    if (prayer == null) {
      throw Exception('La petición ya no existe');
    }

    if (prayer['user_id'] != user.id) {
      throw Exception('Solo puedes eliminar tus propias peticiones');
    }

    await _client.from('prayer_requests').delete().eq('id', prayerRequestId);
  }

  static String categoryLabel(String value) {
    switch (value) {
      case 'salud':
        return 'salud';
      case 'matrimonio':
        return 'matrimonio';
      case 'familia':
        return 'familia';
      case 'hijos':
        return 'hijos';
      case 'trabajo':
        return 'trabajo';
      case 'finanzas':
        return 'finanzas';
      case 'proteccion':
        return 'protección';
      case 'estudios':
        return 'estudios';
      case 'direccion':
        return 'dirección de Dios';
      case 'paz':
        return 'paz';
      case 'sanidad_emocional':
        return 'sanidad emocional';
      case 'fortaleza_espiritual':
        return 'fortaleza espiritual';
      case 'liberacion':
        return 'liberación';
      default:
        return 'una petición';
    }
  }
}