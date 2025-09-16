import 'dart:async';
import 'dart:math';

import 'package:coin_cz/common/decimal/decimal_ext.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/boltz/boltz.dart';
import 'package:coin_cz/features/lightning/lightning.dart';
import 'package:coin_cz/features/receive/providers/providers.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/logger.dart';

final _logger = CustomLogger(FeatureFlag.send);

final sendAssetSetupProvider = AutoDisposeAsyncNotifierProviderFamily<
    SendAssetTransactionSetupNotifier, bool, SendAssetArguments>(
  SendAssetTransactionSetupNotifier.new,
);

class SendAssetTransactionSetupNotifier
    extends AutoDisposeFamilyAsyncNotifier<bool, SendAssetArguments> {
  @override
  FutureOr<bool> build(SendAssetArguments arg) async {
    final input = ref.read(sendAssetInputStateProvider(arg));
    final inputValue = input.valueOrNull;
    if (inputValue == null || input.isLoading) {
      return false;
    }

    ref.listen(sendAssetInputStateProvider(arg), (prev, next) async {
      final isPrevAltUsd = prev!.value!.asset.isAltUsdt;
      final isNextAltUsd = next.value!.asset.isAltUsdt;
      if (!isPrevAltUsd || !isNextAltUsd) return;

      if (prev.value == null || next.value == null) return;

      final isAmountChanged = prev.value!.amount != next.value!.amount;
      if (isPrevAltUsd && isNextAltUsd && isAmountChanged) {
        final input = ref.read(sendAssetInputStateProvider(arg)).value!;
        await _initUSDtSwap(input);
      }
    });

    if (inputValue.externalSweepPrivKey != null) {
      return _initPrivateKeySweep(inputValue, arg);
    }

    if (inputValue.isLightning) {
      return _initLightning(inputValue);
    }

    if (inputValue.asset.isAltUsdt) {
      return _initUSDtSwap(inputValue);
    }

    if (inputValue.asset.isBTC) {
      return _initBitcoin(inputValue);
    }

    return true;
  }

  Future<bool> _initLightning(SendAssetInputState input) async {
    if (input.isLnurl) {
      // Get invoice from lnurlp
      final invoice = await ref.read(lnurlProvider).callLnurlPay(
            payParams: input.lnurlData!.payParams!,
            amountSatoshis: input.amount,
          );

      if (invoice == null) {
        throw LightningInvoiceNotFoundError();
      }

      ref
          .read(sendAssetInputStateProvider(arg).notifier)
          .updateAddressFieldText(invoice);
    }

    //NOTE - Need re-read input because the addressFieldText could update
    final updatedInput = ref.watch(sendAssetInputStateProvider(arg));
    final updatedInputValue = updatedInput.valueOrNull;
    if (!updatedInput.isLoading &&
        updatedInputValue != null &&
        !updatedInputValue.isBoltzToBoltzSwap) {
      return ref
          .read(boltzSubmarineSwapProvider.notifier)
          .prepareSubmarineSwap(address: updatedInputValue.addressFieldText);
    }
    return false;
  }

  Future<bool> _initUSDtSwap(SendAssetInputState input) async {
    // get refund address
    final refundAddress = await ref.read(liquidProvider).getReceiveAddress();
    _logger.debug("[Send][Sideshift] refundAddress: $refundAddress");
    if (refundAddress == null) {
      throw SideshiftRefundAddressNotFoundError();
    }

    final swapPair = input.swapPair;
    if (swapPair == null) {
      throw Exception('Swap pair is null');
    }
    // convert for swap order (ie, 100,000,000  -> $1.00)
    final amountForSwap = DecimalExt.fromDouble(
        input.amount / pow(10, Asset.usdtLiquid().usdtLiquidPrecision));

    // start order
    final swapOrderRequest = SwapOrderRequest(
      from: SwapAsset.fromAsset(Asset.usdtLiquid()),
      to: SwapAsset.fromAsset(input.asset),
      refundAddress: refundAddress.address,
      receiveAddress: input.addressFieldText,
      amount: amountForSwap,
      type: SwapOrderType.fixed,
    );

    //TODO: Need to propagate error here?
    await ref
        .read(swapOrderProvider(SwapArgs(pair: swapPair)).notifier)
        .createSendOrder(swapOrderRequest);

    // set service order id on input state
    final swapOrder =
        ref.read(swapOrderProvider(SwapArgs(pair: swapPair))).valueOrNull;
    if (swapOrder == null || swapOrder.order == null) {
      throw Exception('Swap order is null');
    }
    ref
        .read(sendAssetInputStateProvider(arg).notifier)
        .setServiceOrderId(swapOrder.order!.id);

    return true;
  }

  Future<bool> _initBitcoin(SendAssetInputState input) async {
    final feeRates = await ref.read(onChainFeeProvider.future);
    _logger.debug('[Send][Bitcoin] Fee Rates: $feeRates');
    return true;
  }

  Future<bool> _initPrivateKeySweep(
      SendAssetInputState input, SendAssetArguments args) async {
    try {
      final address = await ref
          .read(receiveAssetAddressProvider((input.asset, null)).future);

      if (address.isEmpty) {
        throw Exception('Address is null');
      }

      await ref
          .read(sendAssetInputStateProvider(args).notifier)
          .updateAddressFieldText(address);

      return true;
    } catch (error) {
      throw Exception('Failed to retrieve address: $error');
    }
  }
}
