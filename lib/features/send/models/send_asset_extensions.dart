import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';

/// Asset extensions for send flow
extension SendAssetExtensions on Asset {
  // should show conversion
  bool get shouldShowConversionOnSend {
    return isBTC || isLBTC || isLightning;
  }

  // should LN/LQ toggle button
  bool get shouldLNLQToggleButton {
    return isLBTC || isLightning;
  }

  // allow usd toggle
  bool get shouldAllowUsdToggleOnSend {
    return isBTC || isLBTC;
  }

  // should show use all funds button
  bool get shouldShowUseAllFundsButton {
    return !isLightning;
  }

  // display symbol
  String get symbol {
    if (isBTC) {
      return 'BTC';
    } else if (isLBTC) {
      return 'L-BTC';
    } else if (isLightning) {
      return 'Sats';
    } else if (isUSDt) {
      return 'USDt';
    }
    return ticker;
  }

  // fee currency symbol
  String get feeCurrencySymbol {
    if (isUSDt) {
      return 'USDt';
    }
    return 'USD';
  }

  // network
  String get network => isBTC ? 'Bitcoin' : 'Liquid';

  NetworkType get networkType =>
      isBTC ? NetworkType.bitcoin : NetworkType.liquid;

  // provider name
  String get providerName {
    if (isLightning) {
      return 'Boltz';
    } else if (isSideshift) {
      return 'Shift';
    }
    return '';
  }
}
