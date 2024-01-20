import 'package:aqua/features/receive/providers/providers.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReceiveConversionWidget extends ConsumerWidget {
  final Asset asset;

  const ReceiveConversionWidget({
    Key? key,
    required this.asset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFinalToggled = ref.watch(amountEnteredIsFiatToggledProvider);
    final satsStr = isFinalToggled && asset.isLightning ? ' sats' : '';
    String conversionValue =
        ref.watch(receiveAssetAmountConversionDisplayProvider(asset)).when(
              data: (value) => '≈ $value$satsStr',
              loading: () => '≈ 0',
              error: (error, stack) => '≈ 0',
            );

    return Text(conversionValue);
  }
}
