import 'package:aqua/features/receive/providers/providers.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:flutter/material.dart';
import 'package:aqua/data/provider/fiat_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class BoltzFeeWidget extends ConsumerWidget {
  final Asset asset;
  final String? amountEntered;
  final int reverseClaimFee;
  final double reversePercentage;
  final int reverseLockupFee;

  const BoltzFeeWidget({
    Key? key,
    required this.asset,
    required this.amountEntered,
    required this.reverseClaimFee,
    required this.reversePercentage,
    required this.reverseLockupFee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFiatToggled = ref.watch(amountEnteredIsFiatToggledProvider);
    String? userEnteredValue = amountEntered;
    if (amountEntered == null || userEnteredValue == "") {
      userEnteredValue = '0';
    }
    String? userEnteredValueInSats = userEnteredValue;
    if (isFiatToggled) {
      userEnteredValueInSats =
          ref.watch(receiveAssetAmountConversionDisplayProvider(asset)).when(
                data: (value) => value,
                loading: () => '0',
                error: (error, stack) => '0',
              );
    }
    final totalServiceFeeSats = reverseClaimFee +
        reverseLockupFee +
        (reversePercentage / 100 * double.parse(userEnteredValueInSats!));

    final assetBalanceFiatAmount = ref
            .watch(satsToFiatProvider(totalServiceFeeSats.round()))
            .asData
            ?.value ??
        '';

    return Text(
        "Service Fee: ${totalServiceFeeSats.ceil()} sats ($assetBalanceFiatAmount)");
  }
}
