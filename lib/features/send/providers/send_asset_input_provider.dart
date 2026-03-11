/*
 * This provider is responsible for handling the state management of send asset
 * flow.
 */

import 'dart:async';

import 'package:aqua/common/exceptions/selection_unavailable_exception.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';
import 'package:ui_components/ui_components.dart';

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
    // Assets without fiat rates should always use BTC display unit, not global preference
    // This includes USDt and other assets that don't have BTC/LBTC/Lightning fiat rate support
    final displayUnit = !asset.hasFiatRate
        ? SupportedDisplayUnits.btc
        : ref.watch(displayUnitsProvider).currentDisplayUnit;
    final initialInputUnit = displayUnit.toInputUnit();
    const initialInputType = AquaAssetInputType.crypto;
    final currentRate = ref.watch(exchangeRatesProvider).currentCurrency;

    // if: networkAmount is provided, use it
    // else: try parse the amount entered as text
    final networkAmount = arg.networkAmount != null
        ? arg.networkAmount!.amount.toBigInt().toInt()
        : (amountFieldText != null
            ? ref.read(formatterProvider).parseAssetAmountToSats(
                  amount: amountFieldText,
                  precision: asset.isBTC || asset.isLBTC || asset.isLightning
                      ? displayUnit.getDisplayPrecision(asset)
                      : asset.precision,
                  asset: asset,
                  forcedDisplayUnit: displayUnit,
                )
            : 0);

    // now if amountFieldText is null, we need to convert the networkAmount to displayAmount
    // but only if networkAmount is not 0 (default)
    if (amountFieldText == null && networkAmount != 0) {
      amountFieldText = ref.read(formatProvider).formatAssetAmount(
            amount: networkAmount,
            asset: asset,
            displayUnitOverride: displayUnit,
          );
    }

    final convertedAmount = networkAmount == 0
        ? asset.isNonSatsAsset
            ? null
            : _formatZeroFiat(currentRate)
        : await ref.read(amountInputMutationsProvider).getConvertedAmount(
              amountSats: networkAmount,
              asset: asset,
              isFiatAmountInput: initialInputType.isFiat,
            );
    final balanceInSats = await ref.read(balanceProvider).getBalance(asset);
    final service = ref.read(amountInputServiceProvider);
    final balanceDisplay = service.getBalanceDisplay(
      balanceInSats: balanceInSats,
      type: initialInputType,
      unit: displayUnit.toInputUnit(),
      rate: currentRate,
      asset: asset,
    );
    final balanceFiatDisplay = await ref
        .read(satsToFiatDisplayWithSymbolProvider(balanceInSats).future);
    final lnurlData = arg.lnurlParseResult;
    final externalPrivateKey = arg.externalPrivateKey;
    final transactionType = determineTransactionType(arg);

    List<Asset>? ambiguousAssets;

    if (addressInput != null && addressInput.isNotEmpty) {
      final parsedInput = await ref.read(addressParserProvider).parseInput(
            input: addressInput,
            asset: asset,
          );
      ambiguousAssets = parsedInput?.ambiguousAssets;
    }

    final isValidAddressInClipboard =
        await _validateAddress(asset, clipboardContent);

    if (!isValidAddressInClipboard) {
      return SendAssetInputState(
        asset: asset,
        swapPair: getSwapPair(asset),
        addressFieldText: addressInput,
        amount: networkAmount,
        amountFieldText: amountFieldText,
        balanceInSats: balanceInSats,
        balanceDisplay: balanceDisplay,
        balanceFiatDisplay: balanceFiatDisplay,
        displayConversionAmount: convertedAmount,
        feeAsset: asset.defaultFeeAsset,
        lnurlData: lnurlData,
        externalSweepPrivKey: externalPrivateKey,
        transactionType: transactionType,
        rate: currentRate,
        inputUnit: initialInputUnit,
        inputType: initialInputType,
        ambiguousAssets: ambiguousAssets,
      );
    }

    return SendAssetInputState(
      asset: asset,
      swapPair: getSwapPair(asset),
      clipboardAddress: clipboardContent,
      addressFieldText: addressInput,
      amount: networkAmount,
      amountFieldText: amountFieldText,
      balanceInSats: balanceInSats,
      balanceDisplay: balanceDisplay,
      balanceFiatDisplay: balanceFiatDisplay,
      displayConversionAmount: convertedAmount,
      feeAsset: asset.defaultFeeAsset,
      lnurlData: lnurlData,
      externalSweepPrivKey: externalPrivateKey,
      transactionType: transactionType,
      rate: currentRate,
      inputUnit: initialInputUnit,
      inputType: initialInputType,
      ambiguousAssets: ambiguousAssets,
    );
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

    if (balanceInSats == 0) {
      // Don't enable send max if balance is 0
      return;
    }

    final balanceFiat = asset.isUSDt
        ? ref.read(amountInputServiceProvider).formatUsdtAmount(
              amountInSats: balanceInSats,
              asset: asset,
              targetCurrency: state.value!.rate.currency,
              currencyFormat: state.value!.rate.currency.format,
              withSymbol: false,
            )
        : await ref
            .read(fiatProvider)
            .getSatsToFiatDisplay(balanceInSats, false);

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

    final newState = state.value!.copyWith(
      isSendAllFunds: enable,
      amount: amountSats,
      amountFieldText: enable ? textFieldAmount : state.value!.amountFieldText,
      displayConversionAmount: amount,
      usdtCryptoAmount: null,
    );

    state = AsyncValue.data(newState);
  }

  String setType(AquaAssetInputType type) {
    final currentState = state.value!;
    final isCrypto = type == AquaAssetInputType.crypto;

    if (type == currentState.inputType) {
      return currentState.amount == 0
          ? ''
          : (currentState.amountFieldText ?? '');
    }

    final service = ref.read(amountInputServiceProvider);
    final balanceDisplay = service.getBalanceDisplay(
      balanceInSats: currentState.balanceInSats,
      type: type,
      unit: isCrypto ? currentState.inputUnit : AquaAssetInputUnit.crypto,
      rate: currentState.rate,
      asset: currentState.asset,
    );

    if (currentState.amount == 0) {
      final conversionAmount = isCrypto
          ? _formatZeroFiat(currentState.rate)
          : service.getBalanceDisplay(
              balanceInSats: 0,
              type: AquaAssetInputType.crypto,
              unit: currentState.inputUnit,
              rate: currentState.rate,
              asset: currentState.asset,
            );

      state = AsyncValue.data(currentState.copyWith(
        inputType: type,
        inputUnit:
            isCrypto ? currentState.inputUnit : AquaAssetInputUnit.crypto,
        amountFieldText: null,
        displayConversionAmount:
            currentState.asset.isNonSatsAsset ? null : conversionAmount,
        usdtCryptoAmount: null,
        balanceDisplay: balanceDisplay,
      ));
      return '';
    }

    String? convertedText;
    if (isCrypto) {
      final displayUnit =
          SupportedDisplayUnits.fromAssetInputUnit(currentState.inputUnit);
      convertedText = ref.read(formatProvider).formatAssetAmount(
            amount: currentState.amount,
            asset: currentState.asset,
            displayUnitOverride: displayUnit,
          );
    } else {
      if (currentState.asset.isUSDt) {
        convertedText = service.formatUsdtAmount(
          amountInSats: currentState.amount,
          asset: currentState.asset,
          targetCurrency: currentState.rate.currency,
          currencyFormat: currentState.rate.currency.format,
          withSymbol: false,
        );
      } else {
        final fiatRateData = ref
            .read(fiatRatesProvider)
            .valueOrNull
            ?.firstWhereOrNull(
                (r) => r.code == currentState.rate.currency.value);
        if (fiatRateData?.rate != null && fiatRateData!.rate > 0) {
          final fiat = ref.read(fiatProvider);
          final fiatAmount = fiat.satoshiToFiat(
            currentState.asset,
            currentState.amount,
            Decimal.parse(fiatRateData.rate.toString()),
          );
          convertedText = fiat.formatFiat(
            fiatAmount,
            currentState.rate.currency.value,
            withSymbol: false,
          );
        }
      }
    }

    final newState = _onInputVariableUpdate(
      type: type,
      text: convertedText,
    );
    state = AsyncValue.data(newState.copyWith(
      inputType: type,
      inputUnit: isCrypto ? currentState.inputUnit : AquaAssetInputUnit.crypto,
      balanceDisplay: balanceDisplay,
    ));
    return convertedText ?? '';
  }

  void setRate(ExchangeRate rate) {
    final currentState = state.value!;

    // Reset amount to default when rate changes
    final service = ref.read(amountInputServiceProvider);
    final displayConversionAmount = currentState.asset.isNonSatsAsset
        ? null
        : (currentState.inputType == AquaAssetInputType.crypto
            ? _formatZeroFiat(rate)
            : service.getBalanceDisplay(
                balanceInSats: 0,
                type: AquaAssetInputType.crypto,
                unit: currentState.inputUnit,
                rate: rate,
                asset: currentState.asset,
              ));

    state = AsyncValue.data(currentState.copyWith(
      rate: rate,
      amountFieldText: null,
      amount: 0,
      displayConversionAmount: displayConversionAmount,
      usdtCryptoAmount: null,
    ));
  }

  void setUnit(AquaAssetInputUnit unit) {
    final currentState = state.value!;

    // Reset amount to default when unit changes
    final service = ref.read(amountInputServiceProvider);

    // Update balance display for the new unit
    final balanceDisplay = service.getBalanceDisplay(
      balanceInSats: currentState.balanceInSats,
      type: currentState.inputType,
      unit: unit,
      rate: currentState.rate,
      asset: currentState.asset,
    );

    // Calculate display conversion amount for zero amount
    final displayConversionAmount = currentState.asset.isNonSatsAsset
        ? null
        : (currentState.inputType == AquaAssetInputType.crypto
            ? _formatZeroFiat(currentState.rate)
            : service.getBalanceDisplay(
                balanceInSats: 0,
                type: AquaAssetInputType.crypto,
                unit: unit,
                rate: currentState.rate,
                asset: currentState.asset,
              ));

    state = AsyncValue.data(currentState.copyWith(
      inputUnit: unit,
      amountFieldText: null,
      amount: 0,
      balanceDisplay: balanceDisplay,
      displayConversionAmount: displayConversionAmount,
      usdtCryptoAmount: null,
    ));
  }

  void setFeeAsset(FeeAsset feeAsset) {
    state = AsyncValue.data(state.value!.copyWith(
      feeAsset: feeAsset,
    ));
  }

  void updateAmountFieldText(String text, {bool isSendAllFunds = false}) {
    final currentState = state.value;
    if (currentState == null) return;

    // Remove thousands separators from the text to prevent parsing issues
    final rawText = text.replaceAll(
        currentState.rate.currency.format.thousandsSeparator, '');

    //NOTE - Enforce precision limit at provider level as a safeguard in case the UI is not doing it
    var trimmedText = trimToPrecision(rawText, currentState.precision);

    // Auto-prepend "0" if text starts with a decimal separator
    trimmedText = normalizeDecimalStart(trimmedText);

    // Compare against raw text (without separators) to detect actual changes
    // If the text hasn't actually changed, don't update anything
    final currentRawText = currentState.amountFieldText
        ?.replaceAll(currentState.rate.currency.format.thousandsSeparator, '');
    if (trimmedText == currentRawText) {
      return;
    }

    final newState = _onInputVariableUpdate(text: trimmedText);

    // Format the text with thousands separators for display
    final formattedText =
        ref.read(amountInputServiceProvider).getFormattedAmountFieldText(
              amountFieldText: trimmedText,
              rate: currentState.rate,
            );

    state = AsyncValue.data(newState.copyWith(
      amountFieldText: formattedText,
      isSendAllFunds: isSendAllFunds,
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
      final parsedAmountInSats =
          parsedInput?.amountInSats ?? state.valueOrNull?.amount ?? 0;
      final ambiguousAssets = parsedInput?.ambiguousAssets;
      final isBoltzToBoltzSwap = parsedInput?.isBoltzToBoltzSwap ?? false;

      if (isLnurl) {
        state = AsyncValue.data(state.valueOrNull!.copyWith(
          asset: parsedInput?.asset ?? asset,
          lnurlData: parsedInput?.lnurlParseResult,
          addressFieldText: parsedAddress,
          amount: parsedLnurlParams.isFixedAmount
              ? parsedLnurlParams.minSendableSats
              : parsedAmountInSats,
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

      final isDiffAsset = isDifferentAsset(asset, parsedAsset);

      final newAsset = switchAsset(
        asset: asset,
        parsedAsset: parsedAsset,
        isLiquidButNotLBTC: ref.read(manageAssetsProvider).isLiquidButNotLBTC,
        isLBTC: ref.read(manageAssetsProvider).isLBTC,
      );

      final fiatAmount =
          await ref.read(amountInputMutationsProvider).getConvertedAmount(
                amountSats: parsedAmountInSats,
                asset: asset,
                isFiatAmountInput: state.value!.isFiatAmountInput,
              );
      final amountinDisplayUnit =
          ref.read(displayUnitsProvider).convertSatsToUnit(
                sats: parsedAmountInSats,
                asset: asset,
              );
      state = AsyncValue.data(state.valueOrNull!.copyWith(
        asset: newAsset,
        swapPair: getSwapPair(newAsset),
        amount: parsedAmountInSats,
        amountFieldText: amountinDisplayUnit.toString(),
        displayConversionAmount: fiatAmount,
        addressFieldText:
            isDiffAsset || isBoltzToBoltzSwap ? parsedAddress : content,
        isBoltzToBoltzSwap: isBoltzToBoltzSwap,
        lnurlData: null, // reset lnurl data since isLnurl is false
        ambiguousAssets: ambiguousAssets,
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

  void selectAsset(Asset selectedAsset) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(
      asset: selectedAsset,
      ambiguousAssets: null,
    ));
  }

  Asset validateAndGetAssetFromId({
    required String? assetId,
    required List<Asset> ambiguousAssets,
  }) {
    if (assetId == null) {
      throw const SelectionUnavailableException();
    }

    return ambiguousAssets.firstWhere(
      (a) => a.id == assetId,
      orElse: () => throw const SelectionUnavailableException(),
    );
  }

  Future<SendAssetArguments?> handleNetworkAssetSelection({
    required String? assetId,
  }) async {
    final currentState = state.valueOrNull;
    if (currentState == null) {
      return null;
    }

    final ambiguousAssets = currentState.ambiguousAssets ?? [];
    final address = currentState.addressFieldText ?? '';

    final asset = validateAndGetAssetFromId(
      assetId: assetId,
      ambiguousAssets: ambiguousAssets,
    );

    final newArgs =
        SendAssetArguments.fromAsset(asset).copyWith(input: address);

    await ref.read(sendAssetInputStateProvider(newArgs).future);

    // Switch to the provider instance for newArgs and update its state.
    // We can't use this.selectAsset() because this refers to the current provider (with arg),
    // not the new provider instance (with newArgs).
    ref.read(sendAssetInputStateProvider(newArgs).notifier).selectAsset(asset);

    return newArgs;
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

  /// Updates the amount to be sent based on the deposit amount from the swap order.
  ///
  /// When using swap services with sender-pays-fees, the amount that needs to be sent
  /// will differ from the original amount the user entered. This method sets the
  /// adjustedAmountToSend field, which will be used for the actual transaction
  /// while preserving the user's original input in the UI.
  void updateSwapDepositAmount(int depositAmountInSats) {
    // Only update adjustedAmountToSend, leaving amount and amountFieldText unchanged
    // This ensures the UI continues to show what the user entered while the transaction
    // uses the adjusted amount with fees included
    state = AsyncValue.data(state.value!.copyWith(
      adjustedAmountToSend: depositAmountInSats,
    ));
  }

  void updateNote(String? note) {
    state = AsyncValue.data(state.valueOrNull!.copyWith(
      note: note,
    ));
  }

  void clearInput() {
    final currentState = state.value!;

    final service = ref.read(amountInputServiceProvider);
    final conversionAmount = currentState.inputType == AquaAssetInputType.crypto
        ? _formatZeroFiat(currentState.rate)
        : service.getBalanceDisplay(
            balanceInSats: 0,
            type: AquaAssetInputType.crypto,
            unit: currentState.inputUnit,
            rate: currentState.rate,
            asset: currentState.asset,
          );

    state = AsyncValue.data(state.value!.copyWith(
      amountFieldText: null,
      amount: 0,
      displayConversionAmount: conversionAmount,
      usdtCryptoAmount: null,
    ));
  }

  //ANCHOR: Private helper methods

  SendAssetInputState _onInputVariableUpdate({
    String? text,
    AquaAssetInputType? type,
    ExchangeRate? rate,
    AquaAssetInputUnit? unit,
  }) {
    final asset = state.value!.asset;
    final balanceInSats = state.value!.balanceInSats;
    text ??= state.value!.amountFieldText;
    type ??= state.value!.inputType;
    rate ??= state.value!.rate;
    unit ??= state.value!.inputUnit;

    final service = ref.read(amountInputServiceProvider);

    // Handle null/empty text case - preserve empty state
    if (text == null || text.isEmpty) {
      final balanceDisplay = service.getBalanceDisplay(
        balanceInSats: balanceInSats,
        type: type,
        unit: unit,
        rate: rate,
        asset: asset,
      );

      // When in fiat input mode and amount is 0, show crypto format, not fiat format
      final displayConversionAmount = asset.isNonSatsAsset
          ? null
          : (type == AquaAssetInputType.fiat
              ? service.getBalanceDisplay(
                  balanceInSats: 0,
                  type: AquaAssetInputType.crypto,
                  unit: unit,
                  rate: rate,
                  asset: asset,
                )
              : _formatZeroFiat(rate));

      return state.value!.copyWith(
        amountFieldText: text, // Preserve null or empty string
        amount: 0,
        balanceInSats: balanceInSats,
        balanceDisplay: balanceDisplay,
        displayConversionAmount: displayConversionAmount,
        usdtCryptoAmount: null,
      );
    }

    final result = service.processAmountInput(
      text: text,
      type: type,
      unit: unit,
      rate: rate,
      asset: asset,
      balanceInSats: balanceInSats,
      currentStateRate: state.value!.rate,
    );

    final zeroDisplay = _formatZeroFiat(rate);
    final fallbackConversionAmount = result.displayConversionAmount ??
        (result.amountInSats == 0 && !asset.isNonSatsAsset
            ? (type == AquaAssetInputType.crypto
                ? zeroDisplay
                : service.getBalanceDisplay(
                    balanceInSats: 0,
                    type: AquaAssetInputType.crypto,
                    unit: unit,
                    rate: rate,
                    asset: asset,
                  ))
            : null);

    // Calculate USDt crypto amount in USD when fiat input with non-USD currency
    final usdtCryptoAmount = (asset.isUSDt &&
            type == AquaAssetInputType.fiat &&
            !rate.currency.isUsd)
        ? service.formatUsdtAmount(
            amountInSats: result.amountInSats,
            asset: asset,
            targetCurrency: FiatCurrency.usd,
            currencyFormat: FiatCurrency.usd.format,
            withSymbol: true,
          )
        : null;

    return state.value!.copyWith(
      amountFieldText: result.formattedAmountText,
      amount: result.amountInSats,
      balanceInSats: balanceInSats,
      balanceDisplay: result.balanceDisplay,
      displayConversionAmount: fallbackConversionAmount,
      usdtCryptoAmount: usdtCryptoAmount,
    );
  }

  String _formatZeroFiat(ExchangeRate rate) {
    return ref.read(formatProvider).formatFiatAmount(
          amount: Decimal.zero,
          specOverride: rate.currency.format,
        );
  }
}
