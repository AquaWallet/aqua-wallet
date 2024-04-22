import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

const usdteName = '(USDT.e)';

class SwapAssetSelectionItem extends HookConsumerWidget {
  const SwapAssetSelectionItem(
    this.asset, {
    super.key,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 62.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12.r)),
      ),
      padding: EdgeInsets.only(left: 19.w, right: 18.w),
      child: Row(
        children: [
          // Icon
          AssetIcon(
            assetId: asset.isLBTC ? 'Layer2Bitcoin' : asset.id,
            assetLogoUrl: asset.logoUrl,
            size: 42.r,
          ),

          SizedBox(width: 17.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                Text(
                  asset.name == "Liquid Bitcoin"
                      ? context.loc.layer2Bitcoin
                      : asset.name.replaceAll(usdteName, '').trim(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context)
                            .colors
                            .popUpMenuButtonSwapScreenTextColor,
                      ),
                ),
                SizedBox(height: 4.h),
                // Ticker
                Text(
                  asset.ticker,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Balance
              Text(
                ref.read(formatterProvider).formatAssetAmountDirect(
                    amount: asset.amount, precision: asset.precision),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context)
                          .colors
                          .popUpMenuButtonSwapScreenTextColor,
                    ),
              ),
              SizedBox(height: 4.h),
              // USD Equivalent
              Consumer(
                builder: (context, watch, _) {
                  final tuple = (asset, asset.amount);
                  final conversion = ref.watch(conversionProvider(tuple));

                  return Text(
                    conversion ?? '-',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
