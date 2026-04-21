import 'package:supabase_flutter/supabase_flutter.dart';

class MediaVideoService {
  static final _client = Supabase.instance.client;

  static bool isYoutubeUrl(String url) {
    final value = url.trim().toLowerCase();
    return value.contains('youtube.com') || value.contains('youtu.be');
  }

  static Future<Map<String, dynamic>> getMediaHome() async {
    final userId = _client.auth.currentUser?.id;

    final featuredVideosResponse = await _client
        .from('media_videos')
        .select()
        .eq('is_active', true)
        .eq('is_featured', true)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false)
        .limit(40);

    final suggestedVideosResponse = await _client
        .from('media_videos')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false)
        .limit(60);

    final featuredVideos = List<Map<String, dynamic>>.from(featuredVideosResponse)
        .where((e) => isYoutubeUrl(e['video_url']?.toString() ?? ''))
        .toList();

    final suggestedVideos = List<Map<String, dynamic>>.from(suggestedVideosResponse)
        .where((e) => isYoutubeUrl(e['video_url']?.toString() ?? ''))
        .toList();

    final featuredMovies =
    featuredVideos.where((e) => e['category'] == 'pelicula').take(10).toList();
    final featuredPreachings =
    featuredVideos.where((e) => e['category'] == 'predicacion').take(10).toList();
    final featuredTestimonies =
    featuredVideos.where((e) => e['category'] == 'testimonio').take(10).toList();

    final suggestedMovies =
    suggestedVideos.where((e) => e['category'] == 'pelicula').take(10).toList();
    final suggestedPreachings =
    suggestedVideos.where((e) => e['category'] == 'predicacion').take(10).toList();
    final suggestedTestimonies =
    suggestedVideos.where((e) => e['category'] == 'testimonio').take(10).toList();

    List<Map<String, dynamic>> featuredSeries = [];
    List<Map<String, dynamic>> suggestedSeries = [];
    List<Map<String, dynamic>> continueWatchingSeries = [];

    try {
      final featuredSeriesResponse = await _client
          .from('media_series')
          .select()
          .eq('is_active', true)
          .eq('is_featured', true)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false)
          .limit(10);

      final suggestedSeriesResponse = await _client
          .from('media_series')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false)
          .limit(12);

      featuredSeries = List<Map<String, dynamic>>.from(featuredSeriesResponse);
      suggestedSeries = List<Map<String, dynamic>>.from(suggestedSeriesResponse);

      if (userId != null) {
        final progressResponse = await _client
            .from('media_series_progress')
            .select()
            .eq('user_id', userId)
            .order('last_watched_at', ascending: false)
            .limit(12);

        final progressRows = List<Map<String, dynamic>>.from(progressResponse);

        if (progressRows.isNotEmpty) {
          final seriesIds = progressRows
              .map((e) => e['series_id']?.toString())
              .whereType<String>()
              .toSet()
              .toList();

          final episodeIds = progressRows
              .map((e) => e['current_episode_id']?.toString())
              .whereType<String>()
              .toSet()
              .toList();

          final seriesRows = seriesIds.isEmpty
              ? <Map<String, dynamic>>[]
              : List<Map<String, dynamic>>.from(
            await _client.from('media_series').select().inFilter('id', seriesIds),
          );

          final episodeRows = episodeIds.isEmpty
              ? <Map<String, dynamic>>[]
              : List<Map<String, dynamic>>.from(
            await _client
                .from('media_series_episodes')
                .select()
                .inFilter('id', episodeIds),
          );

          final seriesMap = {
            for (final row in seriesRows) row['id'].toString(): row,
          };

          final episodeMap = {
            for (final row in episodeRows) row['id'].toString(): row,
          };

          continueWatchingSeries = progressRows.map((progress) {
            final seriesId = progress['series_id']?.toString() ?? '';
            final episodeId = progress['current_episode_id']?.toString() ?? '';

            return {
              'progress': progress,
              'series': seriesMap[seriesId],
              'episode': episodeMap[episodeId],
            };
          }).where((e) => e['series'] != null && e['episode'] != null).toList();
        }
      }
    } catch (_) {
      featuredSeries = [];
      suggestedSeries = [];
      continueWatchingSeries = [];
    }

    return {
      'featuredMovies': featuredMovies,
      'featuredSeries': featuredSeries,
      'featuredPreachings': featuredPreachings,
      'featuredTestimonies': featuredTestimonies,
      'suggestedMovies': suggestedMovies,
      'suggestedSeries': suggestedSeries,
      'suggestedPreachings': suggestedPreachings,
      'suggestedTestimonies': suggestedTestimonies,
      'continueWatchingSeries': continueWatchingSeries,
    };
  }

  static Future<Map<String, dynamic>?> getSeriesById(String seriesId) async {
    final response = await _client
        .from('media_series')
        .select()
        .eq('id', seriesId)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getSeriesEpisodes(String seriesId) async {
    final response = await _client
        .from('media_series_episodes')
        .select()
        .eq('series_id', seriesId)
        .eq('is_active', true)
        .order('season_number', ascending: true)
        .order('episode_number', ascending: true)
        .order('sort_order', ascending: true);

    return List<Map<String, dynamic>>.from(response)
        .where((e) => isYoutubeUrl(e['video_url']?.toString() ?? ''))
        .toList();
  }

  static Future<Map<String, dynamic>?> getSeriesProgress(String seriesId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('media_series_progress')
        .select()
        .eq('user_id', userId)
        .eq('series_id', seriesId)
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  static Future<void> saveSeriesProgress({
    required String seriesId,
    required String episodeId,
    required int watchedSeconds,
    bool completed = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('media_series_progress').upsert(
      {
        'user_id': userId,
        'series_id': seriesId,
        'current_episode_id': episodeId,
        'watched_seconds': watchedSeconds,
        'completed': completed,
        'last_watched_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,series_id',
    );
  }

  static Future<List<Map<String, dynamic>>> getMediaPage({
    required String category,
    required int limit,
    required int offset,
    String searchQuery = '',
  }) async {
    final normalizedQuery = searchQuery.trim();

    if (category == 'series') {
      dynamic query = _client.from('media_series').select();

      query = query.eq('is_active', true);

      if (normalizedQuery.isNotEmpty) {
        query = query.or(
          'title.ilike.%$normalizedQuery%,description.ilike.%$normalizedQuery%',
        );
      }

      final data = await query
          .order('is_featured', ascending: false)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final rows = List<Map<String, dynamic>>.from(data);

      return rows.map((row) {
        return {
          ...row,
          'content_type': 'series',
        };
      }).toList();
    }

    if (category == 'all') {
      final videoLimit = limit;
      final seriesLimit = limit;

      dynamic videosQuery = _client.from('media_videos').select();
      videosQuery = videosQuery.eq('is_active', true);

      if (normalizedQuery.isNotEmpty) {
        videosQuery = videosQuery.or(
          'title.ilike.%$normalizedQuery%,description.ilike.%$normalizedQuery%',
        );
      }

      final videosData = await videosQuery
          .order('is_featured', ascending: false)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false)
          .range(offset, offset + videoLimit - 1);

      dynamic seriesQuery = _client.from('media_series').select();
      seriesQuery = seriesQuery.eq('is_active', true);

      if (normalizedQuery.isNotEmpty) {
        seriesQuery = seriesQuery.or(
          'title.ilike.%$normalizedQuery%,description.ilike.%$normalizedQuery%',
        );
      }

      final seriesData = await seriesQuery
          .order('is_featured', ascending: false)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false)
          .range(offset, offset + seriesLimit - 1);

      final videos = List<Map<String, dynamic>>.from(videosData)
          .where((e) => isYoutubeUrl(e['video_url']?.toString() ?? ''))
          .map((e) => {
        ...e,
        'content_type': e['category'],
      })
          .toList();

      final series = List<Map<String, dynamic>>.from(seriesData).map((e) {
        return {
          ...e,
          'content_type': 'series',
        };
      }).toList();

      final merged = [...videos, ...series];

      merged.sort((a, b) {
        final aFeatured = a['is_featured'] == true ? 1 : 0;
        final bFeatured = b['is_featured'] == true ? 1 : 0;
        if (aFeatured != bFeatured) return bFeatured.compareTo(aFeatured);

        final aSort = (a['sort_order'] as num?)?.toInt() ?? 999999;
        final bSort = (b['sort_order'] as num?)?.toInt() ?? 999999;
        if (aSort != bSort) return aSort.compareTo(bSort);

        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return merged.take(limit).toList();
    }

    final mappedCategory = switch (category) {
      'movie' => 'pelicula',
      'preaching' => 'predicacion',
      'testimony' => 'testimonio',
      _ => '',
    };

    dynamic query = _client.from('media_videos').select();

    query = query.eq('is_active', true);

    if (mappedCategory.isNotEmpty) {
      query = query.eq('category', mappedCategory);
    }

    if (normalizedQuery.isNotEmpty) {
      query = query.or(
        'title.ilike.%$normalizedQuery%,description.ilike.%$normalizedQuery%',
      );
    }

    final data = await query
        .order('is_featured', ascending: false)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final rows = List<Map<String, dynamic>>.from(data)
        .where((e) => isYoutubeUrl(e['video_url']?.toString() ?? ''))
        .toList();

    return rows.map((row) {
      return {
        ...row,
        'content_type': row['category'],
      };
    }).toList();
  }
}