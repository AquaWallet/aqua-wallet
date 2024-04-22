import 'package:aqua/features/settings/manage_assets/models/assets.dart';

/// Asset extensions for receive flow
extension ReceiveAssetExtensions on Asset {
// should show amount input
  bool get shouldShowAmountInputOnReceive {
    if (isSideshift || isLightning) {
      return false;
    }
    return true;
  }

  // should show conversion
  bool get shouldShowConversionOnReceive {
    return isBTC || isLBTC || isLightning;
  }

  // should allow fiat toggle
  bool get shouldAllowFiatToggleOnReceive {
    return isBTC || isLBTC || isLightning;
  }
}
