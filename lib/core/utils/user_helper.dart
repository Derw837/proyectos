import 'package:supabase_flutter/supabase_flutter.dart';

class UserHelper {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>?> ensureAndGetProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final existing = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) {
      return existing;
    }

    final metadata = user.userMetadata ?? {};
    final fullName =
        metadata['full_name']?.toString() ??
            metadata['name']?.toString() ??
            user.email?.split('@').first ??
            'Usuario';

    await _client.from('profiles').insert({
      'id': user.id,
      'full_name': fullName,
      'role': 'user',
      'country': '',
      'city': '',
      'sector': '',
      'approval_status': 'approved',
    });

    final created = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return created;
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    return ensureAndGetProfile();
  }
}