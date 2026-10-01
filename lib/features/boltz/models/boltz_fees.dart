import 'package:boltz/boltz.dart';

class BoltzFees {
  /// Batched submarine swaps (between [SwapLimits.minimalBatched] and
  /// [SwapLimits.minimal]) cannot be cooperatively claimed or closed.
  static bool shouldTryCoopSubmarineSwap({
    required int amountSats,
    required SwapLimits limits,
  }) {
    final minimalBatched = limits.minimalBatched?.toInt();
    if (minimalBatched == null) return true;
    final minimal = limits.minimal.toInt();
    return amountSats >= minimal;
  }
}
