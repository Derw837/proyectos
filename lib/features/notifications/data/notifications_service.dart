import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getMyNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('user_notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> markAsRead(String notificationId) async {
    await _client.from('user_notifications').update({
      'is_read': true,
    }).eq('id', notificationId);
  }

  static Future<void> markAllAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('user_notifications').update({
      'is_read': true,
    }).eq('user_id', user.id).eq('is_read', false);
  }

  static Future<int> getUnreadCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final response = await _client
        .from('user_notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);

    return (response as List).length;
  }

  static Stream<int> unreadCountStream() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const Stream<int>.empty();
    }

    return _client
        .from('user_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((rows) {
      final unread = rows.where((row) => row['is_read'] != true).length;
      return unread;
    });
  }

  static Future<Map<String, dynamic>?> getEventById(String eventId) async {
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
        .eq('id', eventId)
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>?> getPostById(String postId) async {
    final response = await _client
        .from('church_posts')
        .select('''
          id,
          title,
          content,
          created_at,
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
          ),
          church_post_images (
            id,
            image_url
          )
        ''')
        .eq('id', postId)
        .maybeSingle();

    if (response == null) return null;

    final post = Map<String, dynamic>.from(response);

    final images =
    List<Map<String, dynamic>>.from(post['church_post_images'] ?? []);

    post['images'] = images;
    return post;
  }

  static Future<Map<String, dynamic>?> getVideoById(String videoId) async {
    final response = await _client
        .from('church_profile_videos')
        .select('''
        id,
        title,
        description,
        video_url,
        thumbnail_url,
        church_id,
        churches (
          id,
          church_name,
          city,
          country,
          logo_url
        )
      ''')
        .eq('id', videoId)
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  static Stream<Map<String, dynamic>> latestIncomingNotificationStream() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const Stream<Map<String, dynamic>>.empty();
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();

    final subscription = _client
        .from('user_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at')
        .listen((rows) {
      if (rows.isEmpty) return;

      final latest = rows.last;
      controller.add(Map<String, dynamic>.from(latest));
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }
}