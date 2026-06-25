import 'package:aqua/data/data.dart';
import 'package:aqua/features/lightning_address/models/models.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/wallet/wallet.dart';

({String usdtTrailing, String satsUnitTrailing}) formatLnUsernameUpdateFee(
  FormatService formatter,
  DisplayUnitsProvider displayUnits,
  LiquidWalletProduct product,
) {
  final lbtc = Asset.lbtc();
  final amountStr =
      formatter.formatAssetAmount(amount: product.lbtcSatsPrice, asset: lbtc);
  final unitStr = displayUnits.getAssetDisplayUnit(lbtc);
  return (
    usdtTrailing: '\$${product.usdtDisplayPrice}',
    satsUnitTrailing: '$amountStr $unitStr',
  );
}
