import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

const usdteName = '(USDT.e)';

class AssetSelectionDropDownItem extends HookConsumerWidget {
  const AssetSelectionDropDownItem(
    this.asset, {
    super.key,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 62.0,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      padding: const EdgeInsets.only(left: 19.0, right: 18.0),
      child: Row(
        children: [
          // Icon
          AssetIcon(
            assetId: asset.isLBTC ? kLayer2BitcoinId : asset.id,
            assetLogoUrl: asset.logoUrl,
            size: 42.0,
          ),

          const SizedBox(width: 17.0),
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
                const SizedBox(height: 4.0),
                // Ticker
                Text(
                  asset.ticker,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 14.0,
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
              const SizedBox(height: 4.0),
              // USD Equivalent
              Consumer(
                builder: (context, watch, _) {
                  final conversion = ref
                      .watch(conversionProvider((asset, asset.amount)))
                      ?.formattedWithCurrency;

                  return Text(
                    conversion ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 14.0,
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
