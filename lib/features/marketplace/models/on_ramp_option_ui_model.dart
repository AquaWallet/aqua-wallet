import 'package:aqua/config/config.dart';

enum PaymentOption {
  cash(SvgsMarketplace.paymentOptionCash),
  bankTransfer(SvgsMarketplace.paymentOptionBank),
  creditCard(SvgsMarketplace.paymentOptionCard);

  final String icon;

  const PaymentOption(this.icon);
}

enum DeliveryOption {
  btc(Svgs.btcAsset),
  lbtc(Svgs.liquidAsset),
  lightning(Svgs.lightningAsset),
  usdt(Svgs.usdtAsset);

  final String logo;

  const DeliveryOption(this.logo);
}
