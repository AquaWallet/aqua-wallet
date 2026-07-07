import 'dart:async';

import 'package:aqua/data/models/network_amount.dart';
import 'package:aqua/features/lightning_address/lightning_address.dart';
import 'package:aqua/features/lightning_address/services/jan3_api_lightning_addresses.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';

final _logger = CustomLogger(FeatureFlag.lightningAddress);

typedef LnAddressPaymentRequestResult = ({
  PaymentResponse payment,
  SendAssetArguments args
});

final lnAddressPaymentRequestProvider = AutoDisposeAsyncNotifierProvider<
    LnAddressPaymentRequestNotifier, LnAddressPaymentRequestResult?>(
  LnAddressPaymentRequestNotifier.new,
);

class LnAddressPaymentRequestNotifier
    extends AutoDisposeAsyncNotifier<LnAddressPaymentRequestResult?> {
  @override
  Future<LnAddressPaymentRequestResult?> build() async {
    final form = await ref.watch(lnAddressEditInputProvider.future);
    final selectedAsset = form.selectedAsset;
    _logger.debug(
        '[LnAddressPaymentRequest] init: asset=$selectedAsset username=${form.inputUsername}');
    if (selectedAsset == null) return null;

    final api = ref.read(jan3ApiLightningAddressesProvider);
    final assetTicker = selectedAsset.isLBTC
        ? PaymentAssetTicker.lbtc
        : PaymentAssetTicker.usdt;
    _logger.debug(
        '[LnAddressPaymentRequest] creating payment request: ticker=$assetTicker');

    final paymentResp = await api.createPaymentRequest(
      PaymentRequest(asset: assetTicker, lnUsername: form.inputUsername),
    );
    if (!paymentResp.isSuccessful || paymentResp.body == null) {
      throw StateError(
          'createPaymentRequest failed: ${paymentResp.statusCode} ${paymentResp.error}');
    }
    final payment = paymentResp.body!;
    _logger.debug(
        '[LnAddressPaymentRequest] received: id=${payment.paymentId} address=${payment.address} amount=${payment.amountBaseUnits}');

    final args = SendAssetArguments(
      asset: selectedAsset,
      network: 'Liquid',
      input: payment.address,
      networkAmount: NetworkAmount(
        amount: Decimal.fromInt(payment.amountBaseUnits),
        asset: selectedAsset,
      ),
    );
    _logger.debug('[LnAddressPaymentRequest] send input state populated');

    return (payment: payment, args: args);
  }
}
