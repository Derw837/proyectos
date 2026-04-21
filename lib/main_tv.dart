import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:red_cristiana/app_tv.dart';
import 'package:red_cristiana/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error Firebase.initializeApp TV: $e');
  }

  try {
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );
  } catch (e) {
    debugPrint('Error FirebaseMessaging.onBackgroundMessage TV: $e');
  }

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.redcristiana.radio.channel.audio.tv',
      androidNotificationChannelName: 'Radio Red Cristiana TV',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    debugPrint('Error JustAudioBackground.init TV: $e');
  }

  try {
    await Supabase.initialize(
      url: 'https://cqzgoszqladiiluobaxn.supabase.co',
      anonKey: 'sb_publishable_9zuT2ensbTQ3H_lGqLBkCg_VVeWBm3t',
    );
  } catch (e) {
    debugPrint('Error Supabase.initialize TV: $e');
  }

  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('Error MobileAds.initialize TV: $e');
  }

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const AppTv());
}