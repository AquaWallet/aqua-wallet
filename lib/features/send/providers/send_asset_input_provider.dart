/*
 * This provider is responsible for handling the state management of send asset
 * flow.
 */

import 'dart:async';

import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';

final sendAssetInputStateProvider = AutoDisposeAsyncNotifierProviderFamily<
    SendAssetInputStateNotifier,
    SendAssetInputState,
    SendAssetArguments>(SendAssetInputStateNotifier.new);

class SendAssetInputStateNotifier extends AutoDisposeFamilyAsyncNotifier<
    SendAssetInputState, SendAssetArguments> {
  @override
  FutureOr<SendAssetInputState> build(SendAssetArguments arg) async {
    final clipboardContent = await ref.watch(clipboardContentProvider.future);
    final asset = arg.asset;
    final addressInput = arg.input;
    String? amountFieldText = arg.userEnteredAmount?.toString();

    // if: networkAmount is provided, use it
    // else: try parse the amount entered as text
    final networkAmount = arg.networkAmount != null
        ? arg.networkAmount!.amount.toBigInt().toInt()
        : (amountFieldText != null
            ? ref.read(formatterProvider).parseAssetAmountDirect(
                  amount: amountFieldText,
                  precision: asset.precision,
                )
            : 0);

    // now if amountFieldText is null, we need to convert the networkAmount to displayAmount
    // but only if networkAmount is not 0 (default)
    if (amountFieldText == null && networkAmount != 0) {
      amountFieldText = ref.read(formatterProvider).formatAssetAmountDirect(
            amount: networkAmount,
            precision: asset.precision,
          );
    }

    final convertedAmount =
        await ref.read(amountInputMutationsProvider).getConvertedAmount(
              amountSats: networkAmount,
              asset: asset,
              isFiatAmountInput: false,
            );
    final balanceInSats = await ref.read(balanceProvider).getBalance(asset);
    final balanceDisplay = ref.read(formatterProvider).formatAssetAmountDirect(
          amount: balanceInSats,
          precision: asset.precision,
        );
    final balanceFiatDisplay = await ref
        .read(satsToFiatDisplayWithSymbolProvider(balanceInSats).future);
    final lnurlData = arg.lnurlParseResult;
    final externalPrivateKey = arg.externalPrivateKey;
    final transactionType = determineTransactionType(arg);

    final isValidAddressInClipboard =
        await _validateAddress(asset, clipboardContent);

    if (!isValidAddressInClipboard) {
      return SendAssetInputState(
        asset: asset,
        addressFieldText: addressInput,
        amount: networkAmount,
        amountFieldText: amountFieldText,
        balanceInSats: balanceInSats,
        balanceDisplay: balanceDisplay,
        balanceFiatDisplay: balanceFiatDisplay,
        amountConversionDisplay: convertedAmount,
        feeAsset: asset.defaultFeeAsset,
        lnurlData: lnurlData,
        externalSweepPrivKey: externalPrivateKey,
        transactionType: transactionType,
      );
    }

    return SendAssetInputState(
      asset: asset,
      swapPair: _getSwapPair(asset),
      clipboardAddress: clipboardContent,
      addressFieldText: addressInput,
      amount: networkAmount,
      amountFieldText: amountFieldText,
      balanceInSats: balanceInSats,
      balanceDisplay: balanceDisplay,
      balanceFiatDisplay: balanceFiatDisplay,
      amountConversionDisplay: convertedAmount,
      feeAsset: asset.defaultFeeAsset,
      lnurlData: lnurlData,
      externalSweepPrivKey: externalPrivateKey,
      transactionType: transactionType,
    );
  }

  SwapPair? _getSwapPair(Asset asset) {
    return asset.isAltUsdt
        ? SwapPair(
            from: SwapAssetExt.usdtLiquid,
            to: SwapAsset.fromAsset(asset),
          )
        : null;
  }

  // The UI has two components for the clipboard, first the content is displayed
  // in a dedicated view once it is recognized as a valid address. Then user can
  // decide to paste it in the address field by tapping said UI component.
  // This method handles the latter part, therefore the assumption is that the
  // content is already validated.
  Future<void> pasteClipboardContent() async {
    final clipboardAddress = state.value!.clipboardAddress;

    // First update the address field text
    state = AsyncValue.data(state.value!.copyWith(
      addressFieldText: clipboardAddress,
    ));

    // Then process the address
    await _processAddress(clipboardAddress!);
  }

  // QR code is slightly different in that the content is supplied by the user
  // via QR code scanner. Therefore we need to validate the content and update
  // the state accordingly.
  Future<void> pasteScannedQrCode(String? qrCode) async {
    logger.debug("[Send][Input] Scanned QR code: $qrCode");

    // First update the scanned QR code
    state = AsyncValue.data(state.value!.copyWith(
      scannedQrCode: qrCode,
    ));

    if (qrCode == null) {
      state = AsyncValue.error(
        QrScannerInvalidQrParametersException(),
        StackTrace.current,
      );
      return;
    }

    if (qrCode.isEmpty) {
      state = AsyncValue.error(
        AddressParsingException(AddressParsingExceptionType.emptyAddress),
        StackTrace.current,
      );
      return;
    }

    // Then process the address
    await _processAddress(qrCode);
  }

  Future<void> pasteScannedText(String? text) async {
    logger.debug("[Send][Input] Scanned Text: $text");

    if (text == null || text.isEmpty) {
      state = AsyncValue.error(
        AddressParsingException(AddressParsingExceptionType.emptyAddress),
        StackTrace.current,
      );
      return;
    }
    state = AsyncValue.data(state.value!.copyWith(
      scannedText: text,
    ));

    await _processAddress(text);
  }

  Future<void> updateAddressFieldText(String text) async {
    // First update the address field text
    state = AsyncValue.data(state.value!.copyWith(
      addressFieldText: text,
    ));

    // Then process the address
    await _processAddress(text);
  }

  Future<void> setSendMaxAmount(bool enable) async {
    final asset = state.value!.asset;
    final balanceInSats = await ref.read(balanceProvider).getBalance(asset);
    final balanceFiat =
        await ref.read(fiatProvider).getSatsToFiatDisplay(balanceInSats, false);

    final isFiatInput = state.value!.isFiatAmountInput;
    final textFieldAmount =
        isFiatInput ? balanceFiat : state.value!.balanceDisplay;
    final amountSats = enable ? balanceInSats : state.value!.amount;
    final amount =
        await ref.read(amountInputMutationsProvider).getConvertedAmount(
              amountSats: amountSats,
              asset: asset,
              isFiatAmountInput: isFiatInput,
            );
    state = AsyncValue.data(state.value!.copyWith(
      isSendAllFunds: enable,
      amount: amountSats,
      amountFieldText: enable ? textFieldAmount : state.value!.amountFieldText,
      amountConversionDisplay: amount,
    ));
  }

  void setInputType(CryptoAmountInputType type) {
    state = AsyncValue.data(state.value!.copyWith(
      amountInputType: type,
      amount: 0,
      amountFieldText: null,
      amountConversionDisplay: null,
      isSendAllFunds: false,
    ));
  }

  void setFeeAsset(FeeAsset feeAsset) {
    state = AsyncValue.data(state.value!.copyWith(
      feeAsset: feeAsset,
    ));
  }

  Future<void> updateAmountFieldText(String text) async {
    final asset = state.value!.asset;
    final isFiatInput = state.value!.isFiatAmountInput;

    final amountSats =
        await ref.read(amountInputMutationsProvider).getConvertedAmountSats(
              text: text,
              asset: asset,
              isFiatInput: isFiatInput,
            );

    final convertedAmount =
        await ref.read(amountInputMutationsProvider).getConvertedAmount(
              amountSats: amountSats,
              asset: asset,
              isFiatAmountInput: isFiatInput,
            );

    state = AsyncValue.data(state.value!.copyWith(
      amount: amountSats,
      amountFieldText: text,
      amountConversionDisplay: convertedAmount,
      isSendAllFunds: false,
    ));
  }

  void updateFeeAsset(SendAssetFeeOptionModel feeOption) {
    state = AsyncValue.data(state.value!.copyWith(
      feeAsset: feeOption.when(
        bitcoin: (_) => FeeAsset.btc,
        liquid: (fee) => fee.map(
          lbtc: (_) => FeeAsset.lbtc,
          usdt: (_) => FeeAsset.tetherUsdt,
        ),
      ),
      fee: feeOption,
    ));
  }

  Future<bool> _validateAddress(Asset asset, String? content) async {
    if (content == null || content.isEmpty) {
      return false;
    }
    return ref.read(addressParserProvider).isValidAddressForAsset(
          asset: asset,
          address: content,
          accountForCompatibleAssets: true,
        );
  }

  Asset _switchAsset({required Asset asset, required Asset? parsedAsset}) {
    // If the parsed asset is not the same as the current asset, we need to
    // update the asset and the address field text
    final isDiffAsset = _isDifferentAsset(asset, parsedAsset);

    // Special Case: If the original asset is non-LBTC Liquid asset & the
    // parsed asset is LBTC, keep the original asset.
    final isNonLbtcToLbtc = isDiffAsset &&
        ref.read(manageAssetsProvider).isLiquidButNotLBTC(asset) &&
        ref.read(manageAssetsProvider).isLBTC(parsedAsset!);
    return isDiffAsset && !isNonLbtcToLbtc ? parsedAsset! : asset;
  }

  bool _isDifferentAsset(Asset asset, Asset? parsedAsset) =>
      parsedAsset != null && parsedAsset.id != asset.id;

  Future<void> _processAddress(String content) async {
    state = const AsyncValue.loading();
    try {
      final isValid = await _validateAddress(state.value!.asset, content);

      if (!isValid) {
        state = AsyncValue.error(
          AddressParsingException(AddressParsingExceptionType.invalidAddress),
          StackTrace.current,
        );
        return;
      }

      final asset = state.value!.asset;
      final parsedInput = await ref
          .read(addressParserProvider)
          .parseInput(input: content, asset: asset);
      final parsedLnurlParams = parsedInput?.lnurlParseResult?.payParams;
      final isLnurl = parsedLnurlParams != null;
      final parsedAddress = parsedInput?.address;
      final parsedAsset = parsedInput?.asset;
      final parsedAmount = parsedInput?.amount;
      final parsedAmountInSats = _calculateParsedAmount(
        parsedAmount: parsedAmount,
        parsedAsset: parsedAsset,
        currentAmount: state.valueOrNull?.amount,
      );
      final isBoltzToBoltzSwap = parsedInput?.isBoltzToBoltzSwap ?? false;

      if (isLnurl) {
        state = AsyncValue.data(state.valueOrNull!.copyWith(
          asset: parsedInput?.asset ?? asset,
          lnurlData: parsedInput?.lnurlParseResult,
          addressFieldText: parsedAddress,
          amount: parsedLnurlParams.isFixedAmount
              ? parsedLnurlParams.minSendableSats
              : parsedAmountInSats,
          isAmountEditable: !parsedLnurlParams.isFixedAmount,
          isBoltzToBoltzSwap: isBoltzToBoltzSwap,
        ));
        return;
      }

      // If the parsed asset is not compatible with the current asset, throw an
      // error
      if (parsedAddress != null &&
          parsedAsset != null &&
          !asset.isCompatibleWith(parsedAsset)) {
        state = AsyncValue.error(
          AddressParsingException(
            AddressParsingExceptionType.nonMatchingAssetId,
          ),
          StackTrace.current,
        );
        return;
      }

      final isDiffAsset = _isDifferentAsset(asset, parsedAsset);

      final newAsset = _switchAsset(
        asset: asset,
        parsedAsset: parsedAsset,
      );

      final convertedAmount =
          await ref.read(amountInputMutationsProvider).getConvertedAmount(
                amountSats: parsedAmountInSats,
                asset: asset,
                isFiatAmountInput: state.value!.isFiatAmountInput,
              );

      state = AsyncValue.data(state.valueOrNull!.copyWith(
        asset: newAsset,
        swapPair: _getSwapPair(newAsset),
        amount: parsedAmountInSats,
        amountFieldText: parsedAmount?.toString(),
        amountConversionDisplay: convertedAmount,
        addressFieldText:
            isDiffAsset || isBoltzToBoltzSwap ? parsedAddress : content,
        isAmountEditable: !newAsset.isLightning,
        isBoltzToBoltzSwap: isBoltzToBoltzSwap,
        lnurlData: null, // reset lnurl data since isLnurl is false
      ));
    } catch (e) {
      logger.error('Process Address Error', e, StackTrace.current);
      if (e is AddressParsingException) {
        state = AsyncValue.error(e, StackTrace.current);
      } else {
        state = AsyncValue.error(
          AddressParsingException(AddressParsingExceptionType.invalidAddress),
          StackTrace.current,
        );
      }
    }
  }

  void setTransactionType(SendTransactionType type) {
    state = AsyncValue.data(state.valueOrNull!.copyWith(
      transactionType: type,
    ));
  }

  void setServiceOrderId(String serviceOrderId) {
    state = AsyncValue.data(state.valueOrNull!.copyWith(
      serviceOrderId: serviceOrderId,
    ));
  }

  //ANCHOR: Private helper methods
  int _calculateParsedAmount({
    Decimal? parsedAmount,
    Asset? parsedAsset,
    int? currentAmount,
  }) {
    if (parsedAmount == null) {
      return currentAmount ?? 0;
    }

    if (parsedAsset?.isLightning ?? false) {
      return parsedAmount.toInt();
    }

    return ref.read(formatterProvider).parseAssetAmountDirect(
          amount: parsedAmount.toString(),
          precision: parsedAsset?.precision ?? 0,
        );
  }
}

SendTransactionType determineTransactionType(SendAssetArguments args) {
  if (args.transactionType != null) {
    return args.transactionType!;
  }

  if (args.externalPrivateKey != null) {
    return SendTransactionType.privateKeySweep;
  }

  return SendTransactionType.send;
}
