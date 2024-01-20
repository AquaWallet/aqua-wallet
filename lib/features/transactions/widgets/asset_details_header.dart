import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AssetDetailsHeader extends HookConsumerWidget {
  const AssetDetailsHeader({
    Key? key,
    required this.asset,
  }) : super(key: key);

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final balanceAsset = ref
        .watch(assetsProvider)
        .asData
        ?.value
        .firstWhereOrNull((a) => a.id == asset.id);
    final balance = useMemoized(
      () => balanceAsset != null
          ? ref
              .read(formatterProvider)
              .formatAssetAmountFromAsset(asset: balanceAsset)
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
      elevation: 8,
      shape: const RoundedRectangleBorder(),
      margin: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.only(top: kToolbarHeight + 59.h),
        decoration: AppStyle.getHeaderDecoration(darkMode, rounded: false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //ANCHOR - Logo
            AssetIcon(
              assetId: asset.isLBTC ? 'Layer2Bitcoin' : asset.id,
              assetLogoUrl: asset.logoUrl,
              size: 60.r,
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                //ANCHOR - Amount
                Text(
                  balance,
                  style: Theme.of(context).textTheme.headlineLarge,
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
                ? SizedBox(height: 30.h)
                : Container(
                    height: 30.h,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colors.usdContainerBackgroundColor,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                    child: Text(
                      conversion,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .colors
                                .headerUsdContainerTextColor,
                          ),
                    ),
                  ),
            SizedBox(height: 36.h),
          ],
        ),
      ),
    );
  }
}
