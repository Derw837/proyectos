import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  static Future<void> updateMyProfile({
    required String fullName,
    required String country,
    required String city,
    required String sector,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    await _client.from('profiles').update({
      'full_name': fullName,
      'country': country,
      'city': city,
      'sector': sector,
    }).eq('id', user.id);
  }
}