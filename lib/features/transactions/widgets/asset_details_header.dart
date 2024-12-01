import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
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
    final balance = useMemoized(
      () => balanceAsset != null
          ? ref.read(formatterProvider).formatAssetAmountDirect(
              amount: balanceAsset.amount, precision: balanceAsset.precision)
          : '-',
      [balanceAsset],
    );
    final conversion = useMemoized(
      () => balanceAsset != null
          ? ref.read(conversionProvider((balanceAsset, balanceAsset.amount)))
          : null,
      [balanceAsset],
    );

    return Card(
      shape: const ContinuousRectangleBorder(),
      margin: EdgeInsets.only(top: 6.h),
      color: Theme.of(context).colors.headerBackgroundColor,
      elevation: 6,
      child: Container(
        padding: EdgeInsets.only(top: kToolbarHeight + 45.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.maxFinite,
              height: 24.h,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: const AssetStatusIndicator(),
            ),
            //ANCHOR - Logo
            AssetIcon(
              assetId: asset.isLBTC ? 'Layer2Bitcoin' : asset.id,
              assetLogoUrl: asset.logoUrl,
              size: 60.r,
            ),
            SizedBox(height: 22.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                //ANCHOR - Amount
                Text(
                  balance,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                //ANCHOR - Symbol
                Padding(
                  padding: EdgeInsets.only(left: 8.w, bottom: 2.h),
                  child: Text(
                    asset.ticker,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colors.headerSubtitle,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            //ANCHOR - USD Equivalent
            conversion == null
                ? SizedBox(height: 28.h)
                : Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colors.usdPillBackgroundColor,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    padding: EdgeInsets.only(
                        left: 20.w, right: 20.2, top: 3.h, bottom: 2.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          conversion,
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
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
