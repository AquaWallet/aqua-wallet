import 'package:aqua/gen/assets.gen.dart';

enum PaymentOption {
  cash,
  bankTransfer,
  creditCard;

  String get icon => switch (this) {
        cash => UiAssets.marketplace.paymentCash.path,
        bankTransfer => UiAssets.marketplace.paymentBank.path,
        creditCard => UiAssets.marketplace.paymentCard.path,
      };
}

enum DeliveryOption {
  btc,
  lbtc,
  lightning,
  usdt;

  String get logo => switch (this) {
        btc => UiAssets.assetIcons.btc.path,
        lbtc => UiAssets.assetIcons.liquid.path,
        lightning => UiAssets.assetIcons.l2.path,
        usdt => UiAssets.assetIcons.usdt.path,
      };
}
