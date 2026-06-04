import 'package:aqua/data/data.dart';
import 'package:aqua/features/lightning_address/models/models.dart';
import 'package:aqua/features/lightning_address/utils/ln_username_update_fee_format.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/wallet/wallet.dart';

typedef LnUsernameChangeConfirmSummaryAmounts = ({
  String amountCrypto,
  String amountFiat,
});

/// Pure mapping from pre-formatted pieces to summary lines (unit-testable).
LnUsernameChangeConfirmSummaryAmounts lnUsernameChangeConfirmSummaryLines({
  required bool payWithLbtc,
  required String lbtcAmountNumericOnly,
  required String usdtAmountDisplay,
  required String lbtcLineWithDisplayUnit,
  required String usdtLineWithSymbol,
}) {
  if (payWithLbtc) {
    return (
      amountCrypto: '-$lbtcAmountNumericOnly',
      amountFiat: '-$usdtLineWithSymbol',
    );
  }
  return (
    amountCrypto: '-$usdtAmountDisplay',
    amountFiat: '-$lbtcLineWithDisplayUnit',
  );
}

({String amountCrypto, String amountFiat})
    buildLnUsernameChangeConfirmSummaryAmounts({
  required LiquidWalletProduct usernameUpdateProduct,
  required bool payWithLbtc,
  required FormatService formatter,
  required DisplayUnitsProvider displayUnits,
}) {
  final feeDisplayLines =
      formatLnUsernameUpdateFee(formatter, displayUnits, usernameUpdateProduct);
  final lbtcAmountNumericOnly = formatter.formatAssetAmount(
    amount: usernameUpdateProduct.lbtcSatsPrice,
    asset: Asset.lbtc(),
  );
  return lnUsernameChangeConfirmSummaryLines(
    payWithLbtc: payWithLbtc,
    lbtcAmountNumericOnly: lbtcAmountNumericOnly,
    usdtAmountDisplay: usernameUpdateProduct.usdtDisplayPrice,
    lbtcLineWithDisplayUnit: feeDisplayLines.satsUnitTrailing,
    usdtLineWithSymbol: feeDisplayLines.usdtTrailing,
  );
}
