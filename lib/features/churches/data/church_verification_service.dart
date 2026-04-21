import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchVerificationService {
  static final _client = Supabase.instance.client;
  static const String bucket = 'church-media';

  static Future<String> uploadFile({
    required String userId,
    required String folder,
    required String fileName,
    Uint8List? bytes,
    File? file,
    String? contentType,
  }) async {
    final ext = p.extension(fileName).toLowerCase();
    final safeName =
        '${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? '' : ext}';
    final path = 'churches/$userId/$folder/$safeName';

    if (kIsWeb) {
      if (bytes == null) {
        throw Exception('No se recibieron bytes para subir el archivo');
      }

      await _client.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: contentType,
        ),
      );
    } else {
      if (file == null) {
        throw Exception('No se recibió el archivo para subir');
      }

      await _client.storage.from(bucket).upload(
        path,
        file,
        fileOptions: FileOptions(
          upsert: true,
          contentType: contentType,
        ),
      );
    }

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  static Future<void> saveChurchVerification({
    required String userId,
    required String userEmail,
    required String churchName,
    required String pastorName,
    required String country,
    required String city,
    required String sector,
    required String address,
    required String phone,
    required String whatsapp,
    required String description,
    required String certificateUrl,
    required String photo1Url,
    required String photo2Url,
  }) async {
    final existingChurch = await _client
        .from('churches')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    final data = {
      'user_id': userId,
      'church_name': churchName,
      'pastor_name': pastorName,
      'country': country,
      'city': city,
      'sector': sector,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': userEmail,
      'description': description,
      'certificate_url': certificateUrl,
      'photo_1_url': photo1Url,
      'photo_2_url': photo2Url,
      'status': 'pending',
    };

    if (existingChurch != null) {
      await _client
          .from('churches')
          .update(data)
          .eq('id', existingChurch['id']);
    } else {
      await _client.from('churches').insert(data);
    }

    await _client.from('profiles').update({
      'role': 'church',
      'country': country,
      'city': city,
      'sector': sector,
      'approval_status': 'pending',
    }).eq('id', userId);
  }
}