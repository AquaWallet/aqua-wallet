import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const kUsdtDisplayPrecision = 2;

class AssetListItem extends HookConsumerWidget {
  const AssetListItem({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final amount = ref.watch(formatterProvider).formatAssetAmountDirect(
          amount: asset.amount,
          precision: asset.precision,
          roundingOverride: asset.isAnyUsdt ? kUsdtDisplayPrecision : null,
        );
    final usdAmount = ref.watch(conversionProvider((asset, asset.amount)));
    final subtitleTextStyle =
        useMemoized(() => Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ));

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20.r),
      bordered: !darkMode,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(
            AssetTransactionsScreen.routeName,
            arguments: asset,
          ),
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            height: 100.h,
            padding: EdgeInsets.only(left: 16.w, right: 28.w),
            child: Row(
              children: [
                //ANCHOR - Icon
                AssetIcon(
                  // NOTE: For this screen, for liquid we show a "layer2" icon
                  assetId: asset.isLBTC ? 'Layer2Bitcoin' : asset.id,
                  assetLogoUrl: asset.logoUrl,
                  size: 54.r,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //ANCHOR - Name
                          Expanded(
                            child: Text(
                              asset.isLBTC
                                  ? context.loc.layer2Bitcoin
                                  : asset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontSize: context.adaptiveDouble(
                                        mobile: 18.sp, wideMobile: 14.sp),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          //ANCHOR - Amount
                          Text(
                            amount,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //ANCHOR - Symbol
                          Expanded(
                            child: Text(
                              asset.isLBTC
                                  ? 'Liquid & Lightning'
                                  : asset.ticker,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: subtitleTextStyle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          //ANCHOR - USD Equivalent
                          Text(
                            usdAmount ?? '',
                            style: subtitleTextStyle,
                          )
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
