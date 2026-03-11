import 'package:flutter/material.dart';

class SendKeys {
  static const sendAddressInput = Key("address-input");
  static const sendScanQrButton = Key("qr-scan-button");
  static final sendContinueButton = GlobalKey(debugLabel: "continue-button");
  static const sendAssetInput = Key("asset-input");
  static const sendErrorTextMessage = Key("error-text");
  static const sendTransactionAmountDetails =
      Key('send-transaction-amount-details');
  static const assetCryptoAmount = Key('asset-crypto-amount');
  static const sendToAddressValue = Key('send-to-address-value');
}
