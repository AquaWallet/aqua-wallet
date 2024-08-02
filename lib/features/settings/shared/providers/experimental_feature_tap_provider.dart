import 'package:aqua/features/shared/shared.dart';

// NOTE: Number of taps that are required to trigger the hidden feature
const kDefaultTapCountThreshold = 5;

final featureUnlockTapCountProvider = ChangeNotifierProvider.autoDispose(
    (_) => ExperimentalFeatureTapUnlockNotifier());

class ExperimentalFeatureTapUnlockNotifier extends ChangeNotifier {
  int _tapCount = 0;
  bool experimentalFeaturesEnabled = false;

  void increment() {
    _tapCount++;
    if (_tapCount >= kDefaultTapCountThreshold) {
      _tapCount = 0;
      experimentalFeaturesEnabled = true;
      notifyListeners();
    }
  }
}
