import 'dart:async';

import 'package:aqua/features/lightning_address/lightning_address.dart';
import 'package:aqua/features/lightning_address/services/jan3_api_lightning_addresses.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

final _logger = CustomLogger(FeatureFlag.lightningAddress);

final lnAddressUpdatePaymentProvider =
    AutoDisposeAsyncNotifierProvider<LnAddressUpdatePaymentNotifier, void>(
        LnAddressUpdatePaymentNotifier.new);

class LnAddressUpdatePaymentNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final request = await ref.read(lnAddressPaymentRequestProvider.future);
      final input = ref.read(sendAssetInputStateProvider(request.args)).value;
      _logger.debug(
          '[LnAddressUpdate] submit: address=${input?.addressFieldText} amount=${input?.amount} feeAsset=${input?.feeAsset}');
      if (input == null) throw StateError('Send input state is null');

      _logger.debug('[LnAddressUpdate] signing transaction...');
      final rawTx = await ref
          .read(sendTransactionExecutorProvider(request.args))
          .createAndSignTransaction(input: input);

      final api = ref.read(jan3ApiLightningAddressesProvider);
      final response = await api.submitRawTx(SubmitSignedTxRequest(
          paymentId: request.payment.paymentId, rawTx: rawTx));
      if (!response.isSuccessful) {
        throw StateError(
            'submitRawTx failed: ${response.statusCode} ${response.error}');
      }
    });
  }
}
