import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:red_cristiana/core/utils/network_status_helper.dart';

class AudioPlayerService {
  static AudioPlayer _player = AudioPlayer();

  static String? _currentUrl;
  static String? _currentTitle;
  static String? _currentRadioId;
  static String? _currentImageUrl;

  static final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  static final ValueNotifier<String?> currentTitleNotifier = ValueNotifier(null);
  static final ValueNotifier<String?> currentUrlNotifier = ValueNotifier(null);
  static final ValueNotifier<String?> currentRadioIdNotifier =
  ValueNotifier(null);
  static final ValueNotifier<String?> lastErrorNotifier = ValueNotifier(null);

  static bool _initialized = false;

  static AudioPlayer get player => _player;

  static String? get currentUrl => _currentUrl;
  static String? get currentTitle => _currentTitle;
  static String? get currentRadioId => _currentRadioId;
  static String? get currentImageUrl => _currentImageUrl;
  static bool get isPlaying => _player.playing;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _player.playerStateStream.listen((state) {
      isPlayingNotifier.value = state.playing;
    });

    _player.playbackEventStream.listen(
          (_) {},
      onError: (Object error, StackTrace stackTrace) async {
        lastErrorNotifier.value =
        await NetworkStatusHelper.playerMessageForError(error);
        isPlayingNotifier.value = false;
      },
    );
  }

  static Uri? _safeArtUri(String? imageUrl) {
    final value = imageUrl?.trim() ?? '';
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return null;
    return uri;
  }

  static MediaItem _buildMediaItem({
    required String url,
    required String title,
    String? imageUrl,
  }) {
    final artUri = _safeArtUri(imageUrl);

    return MediaItem(
      id: '${url}_${DateTime.now().millisecondsSinceEpoch}',
      album: 'Red Cristiana',
      title: title,
      artist: 'Radio cristiana en vivo',
      displayTitle: title,
      displaySubtitle: 'Red Cristiana',
      artUri: artUri,
    );
  }

  static Future<void> _startStream({
    required String url,
    required String title,
    String? imageUrl,
  }) async {
    final mediaItem = _buildMediaItem(
      url: url,
      title: title,
      imageUrl: imageUrl,
    );

    try {
      await _player.stop();
    } catch (_) {}

    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(url),
        tag: mediaItem,
      ),
      initialPosition: Duration.zero,
      preload: true,
    );

    await _player.play();
  }

  static Future<void> playRadio({
    required String radioId,
    required String url,
    required String title,
    String? imageUrl,
  }) async {
    await init();
    lastErrorNotifier.value = null;

    final isSameRadio = _currentUrl == url;

    _currentRadioId = radioId;
    _currentUrl = url;
    _currentTitle = title;
    _currentImageUrl = imageUrl;

    currentRadioIdNotifier.value = radioId;
    currentUrlNotifier.value = url;
    currentTitleNotifier.value = title;

    if (isSameRadio) {
      if (_player.playing) {
        await pause();
      } else {
        try {
          await resume();
        } catch (_) {
          await retryCurrentRadio();
        }
      }
      return;
    }

    try {
      await _startStream(
        url: url,
        title: title,
        imageUrl: imageUrl,
      );
      isPlayingNotifier.value = true;
      lastErrorNotifier.value = null;
    } catch (e) {
      lastErrorNotifier.value =
      await NetworkStatusHelper.playerMessageForError(e);

      try {
        await hardReset();

        _currentRadioId = radioId;
        _currentUrl = url;
        _currentTitle = title;
        _currentImageUrl = imageUrl;

        currentRadioIdNotifier.value = radioId;
        currentUrlNotifier.value = url;
        currentTitleNotifier.value = title;

        await _startStream(
          url: url,
          title: title,
          imageUrl: imageUrl,
        );

        isPlayingNotifier.value = true;
        lastErrorNotifier.value = null;
      } catch (e2) {
        lastErrorNotifier.value =
        await NetworkStatusHelper.playerMessageForError(e2);
        isPlayingNotifier.value = false;
        rethrow;
      }
    }
  }

  static Future<void> retryCurrentRadio() async {
    final url = _currentUrl;
    final title = _currentTitle;
    final radioId = _currentRadioId;
    final imageUrl = _currentImageUrl;

    if (url == null || title == null || radioId == null) {
      return;
    }

    lastErrorNotifier.value = null;

    try {
      await hardReset();

      _currentRadioId = radioId;
      _currentUrl = url;
      _currentTitle = title;
      _currentImageUrl = imageUrl;

      currentRadioIdNotifier.value = radioId;
      currentUrlNotifier.value = url;
      currentTitleNotifier.value = title;

      await _startStream(
        url: url,
        title: title,
        imageUrl: imageUrl,
      );

      isPlayingNotifier.value = true;
      lastErrorNotifier.value = null;
    } catch (e) {
      lastErrorNotifier.value =
      await NetworkStatusHelper.playerMessageForError(e);
      isPlayingNotifier.value = false;
      rethrow;
    }
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}

    _currentRadioId = null;
    _currentUrl = null;
    _currentTitle = null;
    _currentImageUrl = null;

    currentRadioIdNotifier.value = null;
    currentUrlNotifier.value = null;
    currentTitleNotifier.value = null;
    isPlayingNotifier.value = false;
    lastErrorNotifier.value = null;
  }

  static Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
    isPlayingNotifier.value = false;
  }

  static Future<void> resume() async {
    try {
      await _player.play();
      isPlayingNotifier.value = true;
      lastErrorNotifier.value = null;
    } catch (e) {
      lastErrorNotifier.value =
      await NetworkStatusHelper.playerMessageForError(e);
      rethrow;
    }
  }

  static Future<void> hardReset() async {
    try {
      await _player.stop();
    } catch (_) {}

    try {
      await _player.dispose();
    } catch (_) {}

    _player = AudioPlayer();
    _initialized = false;
    isPlayingNotifier.value = false;

    await init();
  }

  static Future<void> dispose() async {
    await _player.dispose();
  }
}