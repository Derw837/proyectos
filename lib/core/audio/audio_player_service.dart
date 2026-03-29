import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioPlayerService {
  static final AudioPlayer _player = AudioPlayer();

  static String? _currentUrl;
  static String? _currentTitle;
  static String? _currentRadioId;

  static final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  static final ValueNotifier<String?> currentTitleNotifier = ValueNotifier(null);
  static final ValueNotifier<String?> currentUrlNotifier = ValueNotifier(null);
  static final ValueNotifier<String?> currentRadioIdNotifier = ValueNotifier(null);

  static bool _initialized = false;

  static AudioPlayer get player => _player;

  static String? get currentUrl => _currentUrl;
  static String? get currentTitle => _currentTitle;
  static String? get currentRadioId => _currentRadioId;
  static bool get isPlaying => _player.playing;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _player.playerStateStream.listen((state) {
      isPlayingNotifier.value = state.playing;
    });
  }

  static Future<void> playRadio({
    required String radioId,
    required String url,
    required String title,
  }) async {
    await init();

    if (_currentUrl == url) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    _currentRadioId = radioId;
    _currentUrl = url;
    _currentTitle = title;

    currentRadioIdNotifier.value = radioId;
    currentUrlNotifier.value = url;
    currentTitleNotifier.value = title;

    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: url,
          title: title,
          album: 'Red Cristiana',
        ),
      ),
    );

    await _player.play();
  }

  static Future<void> stop() async {
    await _player.stop();
    _currentRadioId = null;
    _currentUrl = null;
    _currentTitle = null;
    currentRadioIdNotifier.value = null;
    currentUrlNotifier.value = null;
    currentTitleNotifier.value = null;
    isPlayingNotifier.value = false;
  }

  static Future<void> pause() async {
    await _player.pause();
    isPlayingNotifier.value = false;
  }

  static Future<void> resume() async {
    await _player.play();
    isPlayingNotifier.value = true;
  }

  static Future<void> dispose() async {
    await _player.dispose();
  }
}