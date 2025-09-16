import 'package:coin_cz/data/provider/conversion_provider.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/transactions/transactions.dart';
import 'package:coin_cz/features/wallet/wallet.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AssetListItem extends HookConsumerWidget {
  const AssetListItem({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    final fiatAmount = ref.watch(conversionProvider((asset, asset.amount)));
    final subtitleTextStyle = useMemoized(
      () => TextStyle(
        height: 1,
        letterSpacing: 0,
        wordSpacing: 1,
        fontWeight: FontWeight.w500,
        color: context.colorScheme.onSurface,
        fontSize: context.adaptiveDouble(
          mobile: 14.0,
          wideMobile: 10.0,
        ),
      ),
      [context.mounted],
    );

    return BoxShadowCard(
      bordered: !darkMode,
      color: context.colorScheme.surface,
      borderRadius: BorderRadius.circular(9.0),
      borderColor: context.colors.cardOutlineColor,
      child: Material(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(9.0),
        child: InkWell(
          onTap: () => context.push(
            AssetTransactionsScreen.routeName,
            extra: asset,
          ),
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular(7.0),
          child: Container(
            height: 96.0,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                //ANCHOR - Icon
                AssetIcon(
                  // NOTE: For this screen, for liquid we show a "layer2" icon
                  assetId: asset.isLBTC ? kLayer2BitcoinId : asset.id,
                  assetLogoUrl: asset.logoUrl,
                  size: 50.0,
                ),
                const SizedBox(width: 16.0),
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
                              asset.isLBTC ? context.loc.l2Bitcoin : asset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                letterSpacing: -0.1,
                                wordSpacing: 1,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                fontSize: context.adaptiveDouble(
                                  mobile: 18.0,
                                  wideMobile: 14.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          //ANCHOR - Amount
                          AssetCryptoAmount(
                            asset: asset,
                            showUnit: false,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: context.adaptiveDouble(
                                mobile: 16.0,
                                wideMobile: 10.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //ANCHOR - Symbol
                          Expanded(
                            child: Text(
                              asset.isUsdtLiquid
                                  ? 'Liquid USDt'
                                  : ref.watch(displayUnitsProvider.select(
                                      (p) => p.getAssetDisplayUnit(asset))),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: subtitleTextStyle,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          //ANCHOR - Fiat Equivalent
                          AssetCryptoAmount(
                            amount: fiatAmount?.formattedWithCurrency ?? '',
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
