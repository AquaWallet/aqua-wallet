import 'package:aqua/features/shared/shared.dart';

final boltzDebugCounterProvider = StateNotifierProvider<BoltzDebugCounter, int>(
  (ref) => BoltzDebugCounter(),
);

class BoltzDebugCounter extends StateNotifier<int> {
  BoltzDebugCounter() : super(0);

  void incrementTapCounter(VoidCallback onThresholdReached) {
    state++;
    if (state >= 3) {
      state = 0;
      onThresholdReached();
    }
  }
}
