import 'package:aqua/features/settings/manage_assets/models/assets.dart';

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
            Asset.usdtTon(),
          ],
        SwapServiceSource.changelly => [
            Asset.usdtEth(),
            Asset.usdtTrx(),
            Asset.usdtBep(),
            Asset.usdtSol(),
            Asset.usdtTon(),
          ],
      };
}
