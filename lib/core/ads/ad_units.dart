import 'dart:io';

class AdUnits {
  AdUnits._();

  // true = anuncios de prueba de Google
  // false = tus anuncios reales de AdMob
  static const bool useTestAds = true;

  // =========================
  // APP ID
  // =========================
  static String get androidAppId => useTestAds
      ? 'ca-app-pub-3940256099942544~3347511713'
      : 'ca-app-pub-3066033429241978~1256311349';

  static String get iosAppId => useTestAds
      ? 'ca-app-pub-3940256099942544~1458002511'
      : '';

  // =========================
  // REWARDED - APOYO GENERAL
  // =========================
  static String get rewardedSupport => useTestAds
      ? 'ca-app-pub-3940256099942544/5224354917'
      : _platformValue(
    android: 'ca-app-pub-3066033429241978/3930576148',
    ios: '',
  );

  // =========================
  // REWARDED - VIDEO
  // =========================
  static String get rewardedVideoSupport => useTestAds
      ? 'ca-app-pub-3940256099942544/5224354917'
      : _platformValue(
    android: 'ca-app-pub-3066033429241978/3606930484',
    ios: '',
  );

  // =========================
  // REWARDED - TV
  // =========================
  static String get rewardedTvSupport => useTestAds
      ? 'ca-app-pub-3940256099942544/5224354917'
      : _platformValue(
    android: 'ca-app-pub-3066033429241978/4091801207',
    ios: '',
  );

  // =========================
  // BANNER - FEED
  // =========================
  static String get feedInlineBanner => useTestAds
      ? 'ca-app-pub-3940256099942544/9214589741'
      : _platformValue(
    android: 'ca-app-pub-3066033429241978/6233093829',
    ios: '',
  );

  // =========================
  // BANNER - VIDEO
  // =========================
  static String get videoBanner => useTestAds
      ? 'ca-app-pub-3940256099942544/9214589741'
      : _platformValue(
    android: 'ca-app-pub-3066033429241978/7101107923',
    ios: '',
  );

  // Si luego quieres banner exclusivo para TV, aquí lo cambiamos.
  static String get tvBanner => useTestAds
      ? 'ca-app-pub-3940256099942544/6300978111'
      : _platformValue(
    android: 'ca-app-pub-3066033429241978/6233093829',
    ios: '',
  );

  static String _platformValue({
    required String android,
    required String ios,
  }) {
    if (Platform.isAndroid) return android;
    if (Platform.isIOS) return ios;
    throw UnsupportedError('Plataforma no soportada');
  }
}