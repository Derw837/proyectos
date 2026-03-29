import 'package:supabase_flutter/supabase_flutter.dart';

class HomeFeedService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getGeneralFeed() async {
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
        .select('''
          id,
          church_id,
          title,
          content,
          image_url,
          created_at
        ''')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final videosResponse = await _client
        .from('church_profile_videos')
        .select('''
          id,
          church_id,
          title,
          description,
          video_url,
          thumbnail_url,
          created_at
        ''')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final feedItems = <Map<String, dynamic>>[];

    // Posts
    for (final raw in postsResponse) {
      final post = Map<String, dynamic>.from(raw);
      final churchId = post['church_id']?.toString() ?? '';
      if (churchId.isEmpty) continue;

      final church = await _client
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
          .eq('id', churchId)
          .eq('status', 'approved')
          .maybeSingle();

      if (church == null) continue;

      final likesResponse = await _client
          .from('church_post_likes')
          .select('id, user_id')
          .eq('post_id', post['id']);

      final likes = List<Map<String, dynamic>>.from(likesResponse);

      final imagesResponse = await _client
          .from('church_post_images')
          .select()
          .eq('post_id', post['id'])
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      feedItems.add({
        'type': 'post',
        'id': post['id'],
        'church_id': churchId,
        'church': church,
        'title': post['title'],
        'content': post['content'],
        'created_at': post['created_at'],
        'images': List<Map<String, dynamic>>.from(imagesResponse),
        'likes_count': likes.length,
        'liked_by_me': user == null
            ? false
            : likes.any((like) => like['user_id'] == user.id),
        'is_my_church': myChurchId != null && myChurchId == churchId,
      });
    }

    // Videos
    for (final raw in videosResponse) {
      final video = Map<String, dynamic>.from(raw);
      final churchId = video['church_id']?.toString() ?? '';
      if (churchId.isEmpty) continue;

      final church = await _client
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
          .eq('id', churchId)
          .eq('status', 'approved')
          .maybeSingle();

      if (church == null) continue;

      feedItems.add({
        'type': 'video',
        'id': video['id'],
        'church_id': churchId,
        'church': church,
        'title': video['title'],
        'content': video['description'],
        'video_url': video['video_url'],
        'thumbnail_url': video['thumbnail_url'],
        'created_at': video['created_at'],
        'is_my_church': myChurchId != null && myChurchId == churchId,
      });
    }

    feedItems.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime(2000);
      final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime(2000);

      return bDate.compareTo(aDate);
    });

    return feedItems;
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
}