import 'package:aqua/data/data.dart';
import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/features/settings/settings.dart' hide AssetIds;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart' hide ResponsiveEx;

const kLUsdtSymbol = 'Liquid USDt';

class AssetListItem extends HookConsumerWidget {
  const AssetListItem({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fiatAmount = ref.watch(conversionProvider((asset, asset.amount)));

    final displayUnit = ref.watch(
        displayUnitsProvider.select((p) => p.getAssetDisplayUnit(asset)));

    return AquaAccountItem(
      onTap: (_) => context.push(
        AssetTransactionsScreen.routeName,
        extra: asset,
      ),
      asset: asset.toUiModel(displayUnit: displayUnit).copyWith(
            name: asset.isLBTC ? context.loc.l2Bitcoin : asset.name,
            //NOTE - There is a lot of stuff that depends on ticker checks, so
            //to stay on the safe side, we're using just replacing the Liquid
            //USDt ticker with L-USDt right here for display instead of changing
            //the ticker for base asset.
            subtitle: asset.isUsdtLiquid ? kLUsdtSymbol : displayUnit,
            amountFiat: fiatAmount?.formattedWithCurrency,
            //NOTE - We need to override the asset icon for home screen listing
            //For that we need to override the asset id and icon url here
            assetId: asset.isLBTC ? AssetIds.layer2 : asset.id,
            iconUrl: asset.isLBTC ? '' : asset.logoUrl,
          ),
      cryptoAmountItem: AssetCryptoAmount(
        asset: asset,
        showUnit: false,
        style: AquaTypography.body1SemiBold.copyWith(
          color: context.aquaColors.textPrimary,
          height: 1.1,
          fontSize: context.adaptiveDouble(
            mobile: 16,
            wideMobile: 10,
          ),
        ),
      ),
      fiatAmountItem: AssetCryptoAmount(
        amount: fiatAmount?.formattedWithCurrency ?? '',
        style: AquaTypography.body2Medium.copyWith(
          color: context.aquaColors.textSecondary,
          height: 1.1,
          fontSize: context.adaptiveDouble(
            mobile: 14,
            wideMobile: 10,
          ),
        ),
      ),
      colors: context.aquaColors,
    );
  }
}
