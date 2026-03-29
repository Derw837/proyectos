import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchService {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getMyChurch() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('churches')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return response;
  }

  static Future<void> updateMyChurch({
    required String churchId,
    required String churchName,
    required String pastorName,
    required String country,
    required String city,
    required String sector,
    required String address,
    required String phone,
    required String whatsapp,
    required String description,
    required String doctrinalBase,
    required String donationAccountName,
    required String donationBankName,
    required String donationAccountNumber,
    required String donationAccountType,
    required String donationInstructions,
  }) async {
    await _client.from('churches').update({
      'church_name': churchName,
      'pastor_name': pastorName,
      'country': country,
      'city': city,
      'sector': sector,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'description': description,
      'doctrinal_base': doctrinalBase,
      'donation_account_name': donationAccountName,
      'donation_bank_name': donationBankName,
      'donation_account_number': donationAccountNumber,
      'donation_account_type': donationAccountType,
      'donation_instructions': donationInstructions,
    }).eq('id', churchId);

    final user = _client.auth.currentUser;
    if (user != null) {
      await _client.from('profiles').update({
        'country': country,
        'city': city,
        'sector': sector,
      }).eq('id', user.id);
    }
  }

  static Future<List<Map<String, dynamic>>> getApprovedChurches() async {
    final response = await _client
        .from('churches')
        .select()
        .eq('status', 'approved')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<String>> getAvailableCountries() async {
    final response = await _client
        .from('churches')
        .select('country')
        .eq('status', 'approved');

    final items = List<Map<String, dynamic>>.from(response);

    final countries = items
        .map((e) => e['country']?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    countries.sort();
    return countries;
  }

  static Future<List<String>> getAvailableCities() async {
    final response = await _client
        .from('churches')
        .select('city')
        .eq('status', 'approved');

    final items = List<Map<String, dynamic>>.from(response);

    final cities = items
        .map((e) => e['city']?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    cities.sort();
    return cities;
  }

  static Future<List<String>> getAvailableSectors() async {
    final response = await _client
        .from('churches')
        .select('sector')
        .eq('status', 'approved');

    final items = List<Map<String, dynamic>>.from(response);

    final sectors = items
        .map((e) => e['sector']?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    sectors.sort();
    return sectors;
  }
}