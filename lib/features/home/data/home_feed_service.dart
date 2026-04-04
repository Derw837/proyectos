import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:red_cristiana/features/prayer/data/prayer_service.dart';

class HomeFeedService {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>> getGeneralFeedPage({
    required int offset,
    int limit = 10,
  }) async {
    final user = _client.auth.currentUser;

    String? myChurchId;

    if (user != null) {
      final myMembership = await _client
          .from('church_memberships')
          .select('church_id')
          .eq('user_id', user.id)
          .maybeSingle();

      myChurchId = myMembership?['church_id']?.toString();
    }

    final postsResponse = await _client
        .from('church_posts')
        .select('id, church_id, title, content, created_at')
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final videosResponse = await _client
        .from('church_profile_videos')
        .select(
      'id, church_id, title, description, video_url, thumbnail_url, created_at',
    )
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final rawPosts = List<Map<String, dynamic>>.from(postsResponse);
    final rawVideos = List<Map<String, dynamic>>.from(videosResponse);
    final prayerRequests = await PrayerService.getPrayerRequests();

    final churchIds = <String>{
      ...rawPosts
          .map((e) => e['church_id']?.toString() ?? '')
          .where((e) => e.isNotEmpty),
      ...rawVideos
          .map((e) => e['church_id']?.toString() ?? '')
          .where((e) => e.isNotEmpty),
    }.toList();

    final churchesMap = <String, Map<String, dynamic>>{};
    if (churchIds.isNotEmpty) {
      final churchesResponse = await _client
          .from('churches')
          .select('''
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
          ''')
          .eq('status', 'approved')
          .inFilter('id', churchIds);

      for (final raw in churchesResponse) {
        final church = Map<String, dynamic>.from(raw);
        final id = church['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          churchesMap[id] = church;
        }
      }
    }

    final postIds = rawPosts
        .map((e) => e['id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final videoIds = rawVideos
        .map((e) => e['id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final postLikesMap = <String, List<Map<String, dynamic>>>{};
    final videoLikesMap = <String, List<Map<String, dynamic>>>{};
    final postImagesMap = <String, List<Map<String, dynamic>>>{};

    if (postIds.isNotEmpty) {
      final postLikesResponse = await _client
          .from('church_post_likes')
          .select('id, user_id, post_id')
          .inFilter('post_id', postIds);

      for (final raw in postLikesResponse) {
        final like = Map<String, dynamic>.from(raw);
        final postId = like['post_id']?.toString() ?? '';
        if (postId.isEmpty) continue;
        postLikesMap.putIfAbsent(postId, () => []).add(like);
      }

      final postImagesResponse = await _client
          .from('church_post_images')
          .select('id, post_id, image_url, sort_order, created_at')
          .inFilter('post_id', postIds)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      for (final raw in postImagesResponse) {
        final image = Map<String, dynamic>.from(raw);
        final postId = image['post_id']?.toString() ?? '';
        if (postId.isEmpty) continue;
        postImagesMap.putIfAbsent(postId, () => []).add(image);
      }
    }

    if (videoIds.isNotEmpty) {
      final videoLikesResponse = await _client
          .from('church_video_likes')
          .select('id, user_id, video_id')
          .inFilter('video_id', videoIds);

      for (final raw in videoLikesResponse) {
        final like = Map<String, dynamic>.from(raw);
        final videoId = like['video_id']?.toString() ?? '';
        if (videoId.isEmpty) continue;
        videoLikesMap.putIfAbsent(videoId, () => []).add(like);
      }
    }

    final feedItems = <Map<String, dynamic>>[];

    for (final post in rawPosts) {
      final churchId = post['church_id']?.toString() ?? '';
      final church = churchesMap[churchId];
      if (church == null) continue;

      final postId = post['id']?.toString() ?? '';
      final likes = postLikesMap[postId] ?? [];
      final images = postImagesMap[postId] ?? [];

      feedItems.add({
        'type': 'post',
        'id': postId,
        'church_id': churchId,
        'church': church,
        'title': post['title'],
        'content': post['content'],
        'created_at': post['created_at'],
        'images': images,
        'likes_count': likes.length,
        'liked_by_me': user == null
            ? false
            : likes.any((like) => like['user_id'] == user.id),
        'is_my_church': myChurchId != null && myChurchId == churchId,
      });
    }

    for (final video in rawVideos) {
      final churchId = video['church_id']?.toString() ?? '';
      final church = churchesMap[churchId];
      if (church == null) continue;

      final videoId = video['id']?.toString() ?? '';
      final likes = videoLikesMap[videoId] ?? [];

      feedItems.add({
        'type': 'video',
        'id': videoId,
        'church_id': churchId,
        'church': church,
        'title': video['title'],
        'content': video['description'],
        'video_url': video['video_url'],
        'thumbnail_url': video['thumbnail_url'],
        'created_at': video['created_at'],
        'likes_count': likes.length,
        'liked_by_me': user == null
            ? false
            : likes.any((like) => like['user_id'] == user.id),
        'is_my_church': myChurchId != null && myChurchId == churchId,
      });
    }

    for (final prayer in prayerRequests) {
      final profile = Map<String, dynamic>.from(prayer['profile'] ?? {});
      final fullName = profile['full_name']?.toString().trim();
      final userName =
      (fullName != null && fullName.isNotEmpty) ? fullName : 'Un usuario';

      feedItems.add({
        'type': 'prayer',
        'id': prayer['id'],
        'created_at': prayer['created_at'],
        'user_id': prayer['user_id'],
        'created_by_me': user != null && prayer['user_id'] == user.id,
        'user_name': userName,
        'category': prayer['category'],
        'is_for_me': prayer['is_for_me'] == true,
        'target_name': prayer['full_name'],
        'user_support_count': prayer['user_support_count'] ?? 0,
        'church_support_count': prayer['church_support_count'] ?? 0,
        'supported_by_me': prayer['supported_by_me'] == true,
        'supported_by_my_church': prayer['supported_by_my_church'] == true,
        'my_church_id': prayer['my_church_id'],
        'requested_my_church': prayer['requested_my_church'] == true,
        'my_church_request_count': prayer['my_church_request_count'] ?? 0,
        'is_church_account': prayer['is_church_account'] == true,
      });
    }

    feedItems.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
      final bDate =
          DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    final hasMore =
        rawPosts.length == limit || rawVideos.length == limit || feedItems.length >= limit;

    return {
      'items': feedItems,
      'has_more': hasMore,
    };
  }

  static Future<void> togglePostLike(String postId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión');
    }

    final existing = await _client
        .from('church_post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('church_post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id);
    } else {
      await _client.from('church_post_likes').insert({
        'post_id': postId,
        'user_id': user.id,
      });
    }
  }

  static Future<void> toggleVideoLike(String videoId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión');
    }

    final existing = await _client
        .from('church_video_likes')
        .select()
        .eq('video_id', videoId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('church_video_likes')
          .delete()
          .eq('video_id', videoId)
          .eq('user_id', user.id);
    } else {
      await _client.from('church_video_likes').insert({
        'video_id': videoId,
        'user_id': user.id,
      });
    }
  }

  static Future<void> togglePrayerUserSupport(String prayerRequestId) async {
    await PrayerService.toggleUserSupport(prayerRequestId);
  }

  static Future<void> togglePrayerChurchSupport(String prayerRequestId) async {
    await PrayerService.toggleChurchSupport(prayerRequestId);
  }

  static Future<void> requestMyChurchPrayer(String prayerRequestId) async {
    await PrayerService.requestMyChurchPrayer(prayerRequestId);
  }

  static Future<void> deletePrayerRequest(String prayerRequestId) async {
    await PrayerService.deletePrayerRequest(prayerRequestId);
  }
}