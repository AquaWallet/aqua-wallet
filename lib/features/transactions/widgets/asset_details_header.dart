import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/data/provider/conversion_provider.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/wallet/wallet.dart';
import 'package:coin_cz/utils/utils.dart';
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
        padding: EdgeInsets.only(
          top: kToolbarHeight +
              context.adaptiveDouble(mobile: 45.0, smallMobile: 15.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.maxFinite,
              height: context.adaptiveDouble(mobile: 24.0, smallMobile: 14.0),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: const AssetStatusIndicator(),
            ),
            //ANCHOR - Logo
            AssetIcon(
              assetId: asset.isLBTC ? kLayer2BitcoinId : asset.id,
              assetLogoUrl: asset.logoUrl,
              size: context.adaptiveDouble(mobile: 60.0, smallMobile: 40.0),
            ),
            SizedBox(
              height: context.adaptiveDouble(mobile: 22.0, smallMobile: 12.0),
            ),
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
            SizedBox(
              height: context.adaptiveDouble(mobile: 14.0, smallMobile: 8.0),
            ),
            //ANCHOR - USD Equivalent
            conversion == null
                ? SizedBox(
                    height:
                        context.adaptiveDouble(mobile: 28.0, smallMobile: 18.0),
                  )
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
            SizedBox(
              height: context.adaptiveDouble(mobile: 40.0, smallMobile: 20.0),
            ),
          ],
        ),
      ),
    );
  }
}
