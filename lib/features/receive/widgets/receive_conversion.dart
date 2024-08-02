import 'package:aqua/features/receive/providers/providers.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReceiveConversionWidget extends ConsumerWidget {
  final Asset asset;
  final String? amountStr;

  const ReceiveConversionWidget(
      {super.key, required this.asset, this.amountStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFiatCurrency = ref.watch(amountCurrencyProvider);
    final isFiatCurrency = selectedFiatCurrency != null;
    final satsStr =
        isFiatCurrency && (asset.isLightning || asset.isLBTC || asset.isBTC)
            ? ' sats'
            : '';
    String conversionValue = ref
        .watch(receiveAssetAmountConversionDisplayProvider(
            (asset, selectedFiatCurrency, amountStr)))
        .when(
          data: (value) => '≈ $value$satsStr',
          loading: () => '≈ 0',
          error: (error, stack) => '≈ 0',
        );

    return Text(conversionValue);
  }
}
