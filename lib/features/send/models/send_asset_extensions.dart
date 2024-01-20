import 'package:aqua/features/settings/manage_assets/models/assets.dart';

import 'models.dart';

/// Asset extensions for send flow
extension SendAssetExtensions on Asset {
  // should disable editing amount
  bool get shouldDisableEditAmountOnSend {
    return isLightning;
  }

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

  // fee currency symbol
  String get feeCurrencySymbol {
    if (isUSDt) {
      return 'USDt';
    }
    return 'USD';
  }

  // provider name
  String get providerName {
    if (isLightning) {
      return 'Boltz';
    } else if (isSideshift) {
      return 'Shift';
    }
    return '';
  }

  // broadcast service
  SendBroadcastServiceType get broadcastService {
    if (isLightning) {
      return SendBroadcastServiceType.boltz;
    }

    return SendBroadcastServiceType.blockstream;
  }
}
