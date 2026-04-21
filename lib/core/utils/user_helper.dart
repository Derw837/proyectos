import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserHelper {
  static final _client = Supabase.instance.client;
  static const _profileCacheKey = 'cached_profile_v1';

  static Future<void> _saveCachedProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileCacheKey, jsonEncode(profile));
  }

  static Future<Map<String, dynamic>?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileCacheKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileCacheKey);
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final existing = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing != null) {
        await _saveCachedProfile(Map<String, dynamic>.from(existing));
      }

      return existing;
    } catch (_) {
      final cached = await getCachedProfile();
      if (cached != null && cached['id']?.toString() == user.id) {
        return cached;
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> createUserProfileWithUserId({
    required String userId,
    required String fullName,
    required String country,
    required String city,
    required String sector,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'full_name': fullName,
      'role': 'user',
      'country': country,
      'city': city,
      'sector': sector,
      'approval_status': 'approved',
    });

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profile != null) {
      await _saveCachedProfile(Map<String, dynamic>.from(profile));
    }

    return profile;
  }

  static Future<Map<String, dynamic>?> createChurchProfilePlaceholderWithUserId({
    required String userId,
    required String fullName,
    required String country,
    required String city,
    required String sector,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'full_name': fullName,
      'role': 'church',
      'country': country,
      'city': city,
      'sector': sector,
      'approval_status': 'pending',
    });

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profile != null) {
      await _saveCachedProfile(Map<String, dynamic>.from(profile));
    }

    return profile;
  }

  static Future<Map<String, dynamic>?> createUserProfile({
    required String fullName,
    required String country,
    required String city,
    required String sector,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    return await createUserProfileWithUserId(
      userId: user.id,
      fullName: fullName,
      country: country,
      city: city,
      sector: sector,
    );
  }

  static Future<Map<String, dynamic>?> createChurchProfilePlaceholder({
    required String fullName,
    required String country,
    required String city,
    required String sector,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    return await createChurchProfilePlaceholderWithUserId(
      userId: user.id,
      fullName: fullName,
      country: country,
      city: city,
      sector: sector,
    );
  }
}