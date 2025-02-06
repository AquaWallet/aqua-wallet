import 'dart:math';

import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';

final maxInt = double.maxFinite.toInt();

class SendAssetAmountConstraints {
  const SendAssetAmountConstraints._({
    required this.minSats,
    required this.maxSats,
  });

  final int minSats;
  final int maxSats;

  factory SendAssetAmountConstraints.aqua() {
    return SendAssetAmountConstraints._(
      minSats: 0,
      maxSats: maxInt,
    );
  }

  factory SendAssetAmountConstraints.lightning(LNURLPayParams? p) {
    final sendMin = p != null ? max(p.minSendableSats, boltzMin) : boltzMin;
    final sendMax = p != null ? min(p.maxSendableSats, boltzMax) : boltzMax;

    return SendAssetAmountConstraints._(
      minSats: sendMin,
      maxSats: sendMax,
    );
  }

  factory SendAssetAmountConstraints.swap(
    SwapRate rate,
    int precision,
  ) {
    final precisionMultiplier =
        DecimalExt.fromDouble(pow(10, precision).toDouble());
    final minWithPrecision = (rate.min * precisionMultiplier).toInt();
    final maxWithPrecision = (rate.max * precisionMultiplier).toInt();

    return SendAssetAmountConstraints._(
      minSats: minWithPrecision,
      maxSats: maxWithPrecision,
    );
  }
}
