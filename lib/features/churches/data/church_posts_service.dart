import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchPostsService {
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

  static Future<List<Map<String, dynamic>>> getMyPosts() async {
    final church = await getMyChurch();
    if (church == null) return [];

    final response = await _client
        .from('church_posts')
        .select()
        .eq('church_id', church['id'])
        .order('created_at', ascending: false);

    final posts = List<Map<String, dynamic>>.from(response);

    for (final post in posts) {
      final images = await _client
          .from('church_post_images')
          .select()
          .eq('post_id', post['id'])
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      post['images'] = List<Map<String, dynamic>>.from(images);
    }

    return posts;
  }

  static Future<List<Map<String, dynamic>>> getChurchPosts(String churchId) async {
    final user = _client.auth.currentUser;

    final response = await _client
        .from('church_posts')
        .select()
        .eq('church_id', churchId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final posts = List<Map<String, dynamic>>.from(response);

    for (final post in posts) {
      final postId = post['id'].toString();

      final likesResponse = await _client
          .from('church_post_likes')
          .select('id, user_id')
          .eq('post_id', postId);

      final likes = List<Map<String, dynamic>>.from(likesResponse);

      final imagesResponse = await _client
          .from('church_post_images')
          .select()
          .eq('post_id', postId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      post['images'] = List<Map<String, dynamic>>.from(imagesResponse);
      post['likes_count'] = likes.length;
      post['liked_by_me'] = user == null
          ? false
          : likes.any((like) => like['user_id'] == user.id);
    }

    return posts;
  }

  static Future<String> uploadPostImage({
    required String filePath,
    required Uint8List bytes,
    required String churchId,
  }) async {
    final extension =
    filePath.contains('.') ? filePath.split('.').last.toLowerCase() : 'jpg';

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = '$churchId/$fileName';

    if (kIsWeb) {
      await _client.storage.from('church-posts').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
    } else {
      await _client.storage.from('church-posts').upload(
        path,
        File(filePath),
        fileOptions: const FileOptions(upsert: true),
      );
    }

    return _client.storage.from('church-posts').getPublicUrl(path);
  }

  static Future<void> createPost({
    required String churchId,
    required String title,
    required String content,
    List<String> imageUrls = const [],
  }) async {
    final inserted = await _client
        .from('church_posts')
        .insert({
      'church_id': churchId,
      'title': title,
      'content': content,
      'image_url': imageUrls.isNotEmpty ? imageUrls.first : null,
      'is_active': true,
    })
        .select()
        .single();

    final postId = inserted['id'].toString();

    for (int i = 0; i < imageUrls.length; i++) {
      await _client.from('church_post_images').insert({
        'post_id': postId,
        'image_url': imageUrls[i],
        'sort_order': i,
      });
    }
  }

  static Future<void> deletePost(String postId) async {
    await _client.from('church_posts').delete().eq('id', postId);
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