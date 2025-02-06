import 'dart:async';
import 'dart:math';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:decimal/decimal.dart';

const kVbPerKb = 1000;

// This component is responsible for calculating the total fee along with the
// fee breakdown for all applicable transaction flows.

final sendAssetFeeProvider = AutoDisposeAsyncNotifierProviderFamily<
    SendAssetFeeNotifier,
    SendAssetFeeState,
    SendAssetArguments>(SendAssetFeeNotifier.new);

class SendAssetFeeNotifier extends AutoDisposeFamilyAsyncNotifier<
    SendAssetFeeState, SendAssetArguments> {
  @override
  FutureOr<SendAssetFeeState> build(SendAssetArguments arg) async {
    final input = await ref.watch(sendAssetInputStateProvider(arg).future);
    final asset = input.asset;
    final txnState = await ref.watch(sendAssetTxnProvider(arg).future);
    final txn = txnState.mapOrNull(created: (tx) => tx.tx);
    final gdkTxn = txn?.mapOrNull(gdkTx: (tx) => tx.gdkTx);

    if (asset.isLiquid || asset.isLightning) {
      return _getLiquidFees(txn, input);
    }

    if (asset.isBTC) {
      return _getBitcoinFees(gdkTxn, input);
    }

    throw UnimplementedError();
  }

  Future<SendAssetFeeState> _getLiquidFees(
    SendAssetOnchainTx? txn,
    SendAssetInputState input,
  ) async {
    final asset = input.asset;
    final isUsdtAssetEnabled = ref.read(manageAssetsProvider).isUsdtEnabled;
    final isTaxiAvailable = !ref.watch(sideswapTaxiProvider).hasError;
    final isTaxiEnabled = isUsdtAssetEnabled && isTaxiAvailable;

    if (!isTaxiEnabled && txn == null) {
      throw FeeTransactionNotFoundError();
    }

    final fee = txn?.mapOrNull(gdkTx: (tx) => tx.gdkTx.fee);
    if (!isTaxiEnabled && fee == null) {
      throw FeeNotFoundError();
    }

    final liquidFeeRateVb = await ref.watch(liquidFeeRateProvider.future);
    final liquidFeeRateKb = (liquidFeeRateVb * kVbPerKb).toInt();

    if (input.feeAsset == FeeAsset.lbtc) {
      return SendAssetFeeState.liquid(
        feeRate: liquidFeeRateKb,
        estimatedFee: fee!.toInt(),
      );
    }

    if (input.feeAsset == FeeAsset.tetherUsdt) {
      final taxiFeeEstimate =
          await ref.read(sideswapTaxiProvider.notifier).estimatedTaxiFeeUsdt(
                input.amount,
                input.isSendAllFunds,
              );
      final taxiFeeEstimateFiat = Decimal.fromInt(taxiFeeEstimate) /
          Decimal.parse(pow(10, asset.precision).toString());
      final fiatRates = await ref.watch(fiatRatesProvider.future);
      final currency = ref.read(prefsProvider).referenceCurrency;
      final usdRate =
          fiatRates.firstWhereOrNull((r) => r.code == currency)?.rate ?? 0;

      return SendAssetFeeState.liquidTaxi(
        estimatedLbtcFee: fee?.toInt() ?? 0,
        estimatedUsdtFee: taxiFeeEstimateFiat.toDouble(),
        lbtcFeeRate: liquidFeeRateKb,
        usdtFeeRate: usdRate,
      );
    }

    throw FeeAssetMismatchError();
  }

  SendAssetFeeState _getBitcoinFees(
    GdkNewTransactionReply? gdkTxn,
    SendAssetInputState input,
  ) {
    if (gdkTxn == null) {
      throw FeeTransactionNotFoundError();
    }

    final transactionVsize = gdkTxn.transactionVsize;
    if (transactionVsize == null) {
      throw UnknownTransactionSizeError();
    }

    final selectedFeeRate = input.fee?.whenOrNull(
      bitcoin: (e) => e.feeRate,
    );

    if (selectedFeeRate == null) {
      throw FeeRateNotFoundError();
    }

    final feeRate = selectedFeeRate.toInt();
    return SendAssetFeeState.bitcoin(
      feeRate: feeRate,
      estimatedFee: (transactionVsize * feeRate).toInt(),
    );
  }
}
