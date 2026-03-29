import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchScheduleService {
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

  static Future<List<Map<String, dynamic>>> getMySchedules() async {
    final church = await getMyChurch();
    if (church == null) return [];

    final response = await _client
        .from('church_schedules')
        .select()
        .eq('church_id', church['id'])
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> createSchedule({
    required String churchId,
    required String dayName,
    required String serviceName,
    required String startTime,
    required String endTime,
  }) async {
    await _client.from('church_schedules').insert({
      'church_id': churchId,
      'day_name': dayName,
      'service_name': serviceName,
      'start_time': startTime,
      'end_time': endTime,
    });
  }

  static Future<void> updateSchedule({
    required String scheduleId,
    required String dayName,
    required String serviceName,
    required String startTime,
    required String endTime,
  }) async {
    await _client.from('church_schedules').update({
      'day_name': dayName,
      'service_name': serviceName,
      'start_time': startTime,
      'end_time': endTime,
    }).eq('id', scheduleId);
  }

  static Future<void> deleteSchedule(String scheduleId) async {
    await _client.from('church_schedules').delete().eq('id', scheduleId);
  }
}