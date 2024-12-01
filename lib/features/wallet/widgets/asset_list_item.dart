import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const kLayer2BitcoinId = 'Layer2Bitcoin';

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
          removeTrailingZeros: !asset.isAnyUsdt,
        );
    final usdAmount = ref.watch(conversionProvider((asset, asset.amount)));
    final subtitleTextStyle = useMemoized(
      () => TextStyle(
        height: 1,
        letterSpacing: 0,
        wordSpacing: 1,
        fontWeight: FontWeight.w500,
        color: context.colorScheme.onSurface,
        fontSize: context.adaptiveDouble(
          mobile: 14.sp,
          wideMobile: 10.sp,
        ),
      ),
      [context.mounted],
    );

    return BoxShadowCard(
      bordered: !darkMode,
      color: context.colorScheme.surface,
      borderRadius: BorderRadius.circular(9.r),
      borderColor: context.colors.cardOutlineColor,
      child: Material(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(9.r),
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(
            AssetTransactionsScreen.routeName,
            arguments: asset,
          ),
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular(7.r),
          child: Container(
            height: 96.h,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                //ANCHOR - Icon
                AssetIcon(
                  // NOTE: For this screen, for liquid we show a "layer2" icon
                  assetId: asset.isLBTC ? kLayer2BitcoinId : asset.id,
                  assetLogoUrl: asset.logoUrl,
                  size: 50.r,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                              style: TextStyle(
                                letterSpacing: -0.1,
                                wordSpacing: 1,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                fontSize: context.adaptiveDouble(
                                  mobile: 18.sp,
                                  wideMobile: 14.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          //ANCHOR - Amount
                          Text(
                            amount,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: context.adaptiveDouble(
                                mobile: 16.sp,
                                wideMobile: 10.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //ANCHOR - Symbol
                          Expanded(
                            child: Text(
                              asset.isLBTC
                                  ? 'LBTC'
                                  : asset.isUsdtLiquid
                                      ? 'Liquid USDt'
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
