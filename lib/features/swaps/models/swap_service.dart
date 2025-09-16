import 'package:coin_cz/features/settings/manage_assets/models/assets.dart';

enum SwapServiceSource {
  sideshift,
  changelly;

  String get displayName => switch (this) {
        SwapServiceSource.sideshift => 'SideShift',
        SwapServiceSource.changelly => 'Changelly',
      };
}

extension SwapServiceAssets on SwapServiceSource {
  List<Asset> get supportedUsdtAssets => switch (this) {
        SwapServiceSource.sideshift => [
            Asset.usdtEth(),
            Asset.usdtTrx(),
            Asset.usdtBep(),
            Asset.usdtSol(),
            Asset.usdtPol(),
            //WARNING: Sideshift supports Ton, but we need to send a memo in transaction to sideshift
            //because for TON swaps they go to all the same deposit address, so we need to send the shiftId
            //in the memo of the tx
            // Asset.usdtTon(),
          ],
        SwapServiceSource.changelly => [
            Asset.usdtEth(),
            Asset.usdtTrx(),
            Asset.usdtBep(),
            Asset.usdtSol(),
            //WARNING: Changelly supports Ton, but we same as Sideshift we need a memo when receiving, so disabling for now
            // Asset.usdtTon(),
          ],
      };
}
