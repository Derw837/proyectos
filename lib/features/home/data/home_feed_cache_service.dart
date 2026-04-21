import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeFeedCacheService {
  static const String _feedItemsKey = 'home_feed_items';
  static const String _feedHasMoreKey = 'home_feed_has_more';
  static const String _feedNextCursorKey = 'home_feed_next_cursor';
  static const String _feedSavedAtKey = 'home_feed_saved_at';

  static Future<void> saveFeed({
    required List<Map<String, dynamic>> items,
    required bool hasMore,
    String? nextCursor,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final encodedItems = jsonEncode(items);

    await prefs.setString(_feedItemsKey, encodedItems);
    await prefs.setBool(_feedHasMoreKey, hasMore);
    await prefs.setString(_feedNextCursorKey, nextCursor ?? '');
    await prefs.setString(_feedSavedAtKey, DateTime.now().toIso8601String());
  }

  static Future<Map<String, dynamic>?> readFeed() async {
    final prefs = await SharedPreferences.getInstance();

    final itemsRaw = prefs.getString(_feedItemsKey);
    if (itemsRaw == null || itemsRaw.isEmpty) return null;

    try {
      final decoded = jsonDecode(itemsRaw);
      final items = List<Map<String, dynamic>>.from(
        (decoded as List).map((e) => Map<String, dynamic>.from(e)),
      );

      return {
        'items': items,
        'has_more': prefs.getBool(_feedHasMoreKey) ?? true,
        'next_cursor': prefs.getString(_feedNextCursorKey),
        'saved_at': prefs.getString(_feedSavedAtKey),
      };
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearFeed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_feedItemsKey);
    await prefs.remove(_feedHasMoreKey);
    await prefs.remove(_feedNextCursorKey);
    await prefs.remove(_feedSavedAtKey);
  }
}