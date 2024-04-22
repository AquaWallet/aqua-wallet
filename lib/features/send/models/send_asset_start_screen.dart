import 'package:decimal/decimal.dart';

enum SendAssetStartScreen {
  addressScreen,
  amountScreen,
  reviewScreen,
}

extension SendAssetStartScreenExtension on SendAssetStartScreen {
  static SendAssetStartScreen determineStartScreen(
      String? address, Decimal? amount) {
    if (address == null && amount == null) {
      return SendAssetStartScreen.addressScreen;
    } else if (amount == null) {
      return SendAssetStartScreen.amountScreen;
    } else {
      return SendAssetStartScreen.reviewScreen;
    }
  }
}
