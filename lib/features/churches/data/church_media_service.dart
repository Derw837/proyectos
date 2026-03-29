import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchMediaService {
  static final _client = Supabase.instance.client;

  static Future<String> uploadChurchImage({
    required String filePath,
    required Uint8List bytes,
    required String churchId,
    required String folder,
  }) async {
    final extension = filePath.contains('.')
        ? filePath.split('.').last.toLowerCase()
        : 'jpg';

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = '$folder/$churchId/$fileName';

    if (kIsWeb) {
      await _client.storage.from('church-media').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
    } else {
      await _client.storage.from('church-media').upload(
        path,
        File(filePath),
        fileOptions: const FileOptions(upsert: true),
      );
    }

    return _client.storage.from('church-media').getPublicUrl(path);
  }

  static Future<void> updateChurchImages({
    required String churchId,
    String? logoUrl,
    String? coverUrl,
  }) async {
    final data = <String, dynamic>{};

    if (logoUrl != null) data['logo_url'] = logoUrl;
    if (coverUrl != null) data['cover_url'] = coverUrl;

    if (data.isEmpty) return;

    await _client.from('churches').update(data).eq('id', churchId);
  }
}