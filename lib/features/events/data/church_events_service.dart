import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchEventsService {
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

  static Future<Map<String, dynamic>?> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    return await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }

  static Future<String> uploadEventImage({
    required String churchId,
    required String filePath,
    required Uint8List bytes,
  }) async {
    final extension =
    filePath.contains('.') ? filePath.split('.').last.toLowerCase() : 'jpg';

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = '$churchId/$fileName';

    if (kIsWeb) {
      await _client.storage.from('church-events').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
    } else {
      await _client.storage.from('church-events').upload(
        path,
        File(filePath),
        fileOptions: const FileOptions(upsert: true),
      );
    }

    return _client.storage.from('church-events').getPublicUrl(path);
  }

  static Future<void> createEvent({
    required String churchId,
    required String title,
    required String description,
    required String eventDate,
    required String startTime,
    required String endTime,
    required String country,
    required String city,
    required String sector,
    required String address,
    String? imageUrl,
  }) async {
    await _client.from('church_events').insert({
      'church_id': churchId,
      'title': title,
      'description': description,
      'event_date': eventDate,
      'start_time': startTime,
      'end_time': endTime,
      'country': country,
      'city': city,
      'sector': sector,
      'address': address,
      'image_url': imageUrl,
      'status': 'published',
    });
  }

  static Future<void> deleteEvent(String eventId) async {
    await _client.from('church_events').delete().eq('id', eventId);
  }

  static Future<List<Map<String, dynamic>>> getMyEvents() async {
    final myChurch = await getMyChurch();
    if (myChurch == null) return [];

    final churchId = myChurch['id'];
    final today = DateTime.now().toIso8601String().split('T').first;

    final response = await _client
        .from('church_events')
        .select()
        .eq('church_id', churchId)
        .gte('event_date', today)
        .order('event_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getPublishedEvents() async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final response = await _client
        .from('church_events')
        .select('''
          id,
          title,
          description,
          event_date,
          start_time,
          end_time,
          country,
          city,
          sector,
          address,
          image_url,
          status,
          church_id,
          churches (
            id,
            church_name,
            city,
            country,
            logo_url,
            cover_url,
            pastor_name,
            address,
            phone,
            whatsapp,
            email,
            description,
            doctrinal_base,
            donation_account_name,
            donation_bank_name,
            donation_account_number,
            donation_account_type,
            donation_instructions,
            spiritual_help_label,
            spiritual_help_url,
            sector,
            status
          )
        ''')
        .eq('status', 'published')
        .gte('event_date', today)
        .order('event_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getChurchEvents(String churchId) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final response = await _client
        .from('church_events')
        .select()
        .eq('church_id', churchId)
        .eq('status', 'published')
        .gte('event_date', today)
        .order('event_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<String>> getAvailableEventCountries() async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final response = await _client
        .from('church_events')
        .select('country')
        .eq('status', 'published')
        .gte('event_date', today);

    final items = List<Map<String, dynamic>>.from(response);

    final countries = items
        .map((e) => e['country']?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    countries.sort();
    return countries;
  }

  static Future<List<String>> getAvailableEventCities() async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final response = await _client
        .from('church_events')
        .select('city')
        .eq('status', 'published')
        .gte('event_date', today);

    final items = List<Map<String, dynamic>>.from(response);

    final cities = items
        .map((e) => e['city']?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    cities.sort();
    return cities;
  }
}