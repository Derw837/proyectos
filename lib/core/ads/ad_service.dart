import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static RewardedAd? _rewardedAd;
  static bool _isLoadingRewarded = false;
  static String? _currentRewardedUnitId;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();

    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: ['777d09b1-73bb-4c02-9635-16ea6ba5bc55'],
      ),
    );
  }

  static Future<void> loadRewardedAd(String adUnitId) async {
    if (_isLoadingRewarded && _currentRewardedUnitId == adUnitId) return;

    _isLoadingRewarded = true;
    _currentRewardedUnitId = adUnitId;

    if (_rewardedAd != null) {
      await _rewardedAd!.dispose();
      _rewardedAd = null;
    }

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;

          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              _rewardedAd = null;
            },
            onAdFailedToShowFullScreenContent: (
                RewardedAd ad,
                AdError error,
                ) {
              ad.dispose();
              _rewardedAd = null;
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isLoadingRewarded = false;
        },
      ),
    );
  }

  static Future<bool> showRewardedAd({
    required String adUnitId,
    required VoidCallback onRewardEarned,
  }) async {
    if (_rewardedAd == null || _currentRewardedUnitId != adUnitId) {
      await loadRewardedAd(adUnitId);
    }

    final ad = _rewardedAd;
    if (ad == null) {
      debugPrint('RewardedAd no está listo todavía');
      return false;
    }

    await ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onRewardEarned();
      },
    );

    _rewardedAd = null;
    return true;
  }
}