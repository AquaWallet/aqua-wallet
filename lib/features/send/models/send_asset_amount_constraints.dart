import 'dart:math';

import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';
import 'package:boltz/boltz.dart';

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

  factory SendAssetAmountConstraints.lightning(
      {required SubmarineFeesAndLimits submarineFees,
      LNURLPayParams? lnurlPayParams}) {
    final sendMin = lnurlPayParams != null
        ? max(lnurlPayParams.minSendableSats,
            submarineFees.lbtcLimits.minimal.toInt())
        : submarineFees.lbtcLimits.minimal.toInt();
    final sendMax = lnurlPayParams != null
        ? min(lnurlPayParams.maxSendableSats,
            submarineFees.lbtcLimits.maximal.toInt())
        : submarineFees.lbtcLimits.maximal.toInt();

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
