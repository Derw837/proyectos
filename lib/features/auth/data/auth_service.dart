import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  static Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.redcristiana://login-callback/',
      authScreenLaunchMode:
      kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  static Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'https://pigoapp.com/reset-password-start',
    );
  }

  static Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(
      UserAttributes(password: password),
    );
  }
}