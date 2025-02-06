import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AssetDetailsHeader extends HookConsumerWidget {
  const AssetDetailsHeader({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsset = ref
        .watch(assetsProvider)
        .asData
        ?.value
        .firstWhereOrNull((a) => a.id == asset.id);
    final conversion = useMemoized(
      () => balanceAsset != null
          ? ref
              .read(conversionProvider((balanceAsset, balanceAsset.amount)))
              ?.formattedWithCurrency
          : null,
      [balanceAsset],
    );

    return Card(
      shape: const ContinuousRectangleBorder(),
      margin: const EdgeInsets.only(top: 6.0),
      color: Theme.of(context).colors.headerBackgroundColor,
      elevation: 6,
      child: Container(
        padding: const EdgeInsets.only(top: kToolbarHeight + 45.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.maxFinite,
              height: 24.0,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: const AssetStatusIndicator(),
            ),
            //ANCHOR - Logo
            AssetIcon(
              assetId: asset.isLBTC ? kLayer2BitcoinId : asset.id,
              assetLogoUrl: asset.logoUrl,
              size: 60.0,
            ),
            const SizedBox(height: 22.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                //ANCHOR - Amount
                GestureDetector(
                  onTap: () => ref.read(prefsProvider).switchBalanceHidden(),
                  child: AssetCryptoAmount(
                    asset: balanceAsset ?? asset,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                    isLoading: balanceAsset == null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            //ANCHOR - USD Equivalent
            conversion == null
                ? const SizedBox(height: 28.0)
                : Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colors.usdPillBackgroundColor,
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: const EdgeInsets.fromLTRB(20.0, 3.0, 20.0, 2.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AssetCryptoAmount(
                          amount: conversion,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color:
                                    Theme.of(context).colors.usdPillTextColor,
                              ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }
}
