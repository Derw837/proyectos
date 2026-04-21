import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getMyNotifications({
    int rawLimit = 120,
    int finalLimit = 60,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('user_notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(rawLimit);

    final rawItems = List<Map<String, dynamic>>.from(response);

    final grouped = <String, Map<String, dynamic>>{};
    final groupedOrder = <String>[];

    for (final raw in rawItems) {
      final item = Map<String, dynamic>.from(raw);

      final type = item['type']?.toString() ?? '';
      final title = item['title']?.toString().trim() ?? '';
      final message = item['message']?.toString().trim() ?? '';
      final relatedId = item['related_id']?.toString() ?? '';
      final churchId = item['church_id']?.toString() ?? '';

      String dayKey = '';
      final createdAt = item['created_at']?.toString() ?? '';
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dayKey =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {}

      final groupKey =
          '$type|$title|$message|$relatedId|$churchId|$dayKey';

      if (!grouped.containsKey(groupKey)) {
        item['grouped_count'] = 1;
        item['duplicate_ids'] = <String>[
          item['id']?.toString() ?? '',
        ].where((e) => e.isNotEmpty).toList();

        grouped[groupKey] = item;
        groupedOrder.add(groupKey);
      } else {
        final current = grouped[groupKey]!;
        final duplicateIds =
        List<String>.from(current['duplicate_ids'] ?? <String>[]);

        final newId = item['id']?.toString() ?? '';
        if (newId.isNotEmpty && !duplicateIds.contains(newId)) {
          duplicateIds.add(newId);
        }

        current['duplicate_ids'] = duplicateIds;
        current['grouped_count'] = (current['grouped_count'] ?? 1) + 1;

        final currentCreatedAt = current['created_at']?.toString() ?? '';
        final incomingCreatedAt = item['created_at']?.toString() ?? '';

        DateTime currentDate;
        DateTime incomingDate;

        try {
          currentDate = DateTime.parse(currentCreatedAt);
        } catch (_) {
          currentDate = DateTime(2000);
        }

        try {
          incomingDate = DateTime.parse(incomingCreatedAt);
        } catch (_) {
          incomingDate = DateTime(2000);
        }

        if (incomingDate.isAfter(currentDate)) {
          current['id'] = item['id'];
          current['created_at'] = item['created_at'];
          current['is_read'] = item['is_read'];
          current['related_id'] = item['related_id'];
        }
      }
    }

    final result = groupedOrder
        .map((key) => grouped[key]!)
        .toList()
      ..sort((a, b) {
        final aDate =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
                DateTime(2000);
        final bDate =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
                DateTime(2000);
        return bDate.compareTo(aDate);
      });

    return result.take(finalLimit).toList();
  }

  static Future<void> markAsRead(String notificationId) async {
    await _client.from('user_notifications').update({
      'is_read': true,
    }).eq('id', notificationId);
  }

  static Future<void> markManyAsRead(List<String> notificationIds) async {
    final cleanIds = notificationIds
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .toList();

    if (cleanIds.isEmpty) return;

    await _client.from('user_notifications').update({
      'is_read': true,
    }).inFilter('id', cleanIds);
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
        .map((rows) => rows.where((row) => row['is_read'] != true).length);
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

    bool initialized = false;
    final knownIds = <String>{};

    final subscription = _client
        .from('user_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at')
        .listen((rows) {
      final mappedRows = rows
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      if (!initialized) {
        for (final row in mappedRows) {
          final id = row['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            knownIds.add(id);
          }
        }
        initialized = true;
        return;
      }

      for (final row in mappedRows) {
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        if (!knownIds.contains(id)) {
          knownIds.add(id);
          controller.add(row);
        }
      }
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }
}