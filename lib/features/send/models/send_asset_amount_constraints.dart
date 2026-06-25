import 'dart:math';

import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/shared/shared.dart';
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
    final batchedMin = submarineFees.lbtcLimits.minimalBatched?.toInt();
    final minSendable = batchedMin == null
        ? kGdkMinSendAmountLbtcSats
        : max(kGdkMinSendAmountLbtcSats,
            batchedMin); // This is almost always kGdkMinSendAmountLbtcSats
    final sendMin = lnurlPayParams != null
        ? max(lnurlPayParams.minSendableSats, minSendable)
        : minSendable;
    final sendMax = lnurlPayParams != null
        ? min(lnurlPayParams.maxSendableSats,
            submarineFees.lbtcLimits.maximal.toInt())
        : submarineFees.lbtcLimits.maximal.toInt();

    return SendAssetAmountConstraints._(
      minSats: sendMin,
      maxSats: sendMax,
    );
  }

  @visibleForTesting
  factory SendAssetAmountConstraints.test({
    required int minSats,
    required int maxSats,
  }) =>
      SendAssetAmountConstraints._(minSats: minSats, maxSats: maxSats);

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
