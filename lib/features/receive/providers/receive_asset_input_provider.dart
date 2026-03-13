/*
 * This provider is responsible for handling the state management of receive
 * asset flow.
 */

import 'dart:async';

import 'package:aqua/common/data_conversion/bip21_encoder.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:ui_components/ui_components.dart';

final receiveAssetInputStateProvider = AutoDisposeAsyncNotifierProviderFamily<
    ReceiveAssetInputStateNotifier,
    ReceiveAmountInputState,
    ReceiveAmountArguments>(ReceiveAssetInputStateNotifier.new);

class ReceiveAssetInputStateNotifier extends AutoDisposeFamilyAsyncNotifier<
    ReceiveAmountInputState, ReceiveAmountArguments> {
  @override
  FutureOr<ReceiveAmountInputState> build(ReceiveAmountArguments arg) async {
    final currentRate = ref.watch(exchangeRatesProvider).currentCurrency;
    final symbol = currentRate.currency.format.symbol;
    final assets = ref.read(assetsProvider).valueOrNull ?? [];
    final balanceInSats = arg.asset.isLightning
        ? assets.firstWhereOrNull((e) => e.isLBTC)?.amount ?? 0
        : assets.firstWhereOrNull((e) => e.id == arg.asset.id)?.amount ?? 0;
    final service = ref.read(amountInputServiceProvider);
    final balanceDisplay = service.getBalanceDisplay(
      balanceInSats: balanceInSats,
      type: AquaAssetInputType.crypto,
      unit: AquaAssetInputUnit.crypto,
      rate: currentRate,
      asset: arg.asset,
    );
    const type = AquaAssetInputType.crypto;

    return ReceiveAmountInputState(
      asset: arg.asset,
      balanceInSats: balanceInSats,
      balanceDisplay: balanceDisplay,
      rate: currentRate,
      swapPair: arg.swapPair,
      displayConversionAmount: '${symbol}0.00',
      inputType: type,
    );
  }

  void updateAmountFieldText(String text) {
    final newState = _onInputVariableUpdate(text: text);
    state = AsyncValue.data(newState);
  }

  void setRate(ExchangeRate rate) {
    final currentState = state.value!;

    // Check if decimal separator format changed between old and new currency
    final oldDecimalSeparator =
        currentState.rate.currency.format.decimalSeparator;
    final newDecimalSeparator = rate.currency.format.decimalSeparator;
    final decimalSeparatorChanged = oldDecimalSeparator != newDecimalSeparator;

    if (currentState.inputType == AquaAssetInputType.fiat &&
        currentState.amountFieldText != null) {
      // IMPORTANT: Parse using the CURRENT currency format, not the new one!
      final cleanedAmount = ref.read(formatterProvider).cleanAmountString(
            currentState.amountFieldText!,
            currentState.rate.currency.format,
          );

      // Treat this numeric value as the amount in the NEW currency
      final amount = double.tryParse(cleanedAmount);
      if (amount != null && amount > 0) {
        final newState = _onInputVariableUpdate(
          rate: rate,
          text: cleanedAmount,
        );
        state = AsyncValue.data(newState.copyWith(rate: rate));
        return;
      }
    } else if (currentState.inputType == AquaAssetInputType.crypto &&
        decimalSeparatorChanged &&
        currentState.amountFieldText != null &&
        currentState.amountFieldText!.isNotEmpty) {
      // For crypto input, amountFieldText is in BTC format (always uses '.' as decimal).
      // Don't apply fiat currency format cleaning - just remove spaces and parse directly.
      final cleanedText = currentState.amountFieldText!
          .replaceAll(' ', '')
          .replaceAll(FormatService.kBitcoinFractionalSeparator, '');

      // Use the cleaned text for re-parsing with the new rate
      final newState = _onInputVariableUpdate(
        text: cleanedText,
        rate: rate,
      );

      state = AsyncValue.data(newState.copyWith(rate: rate));
      return;
    }

    final newState = _onInputVariableUpdate(rate: rate);
    state = AsyncValue.data(newState.copyWith(rate: rate));
  }

  void setUnit(AquaAssetInputUnit unit) {
    final currentState = state.value!;

    if (currentState.inputType == AquaAssetInputType.fiat) {
      final newState = _onInputVariableUpdate(
        unit: unit,
        text: currentState.amountFieldText,
      );
      state = AsyncValue.data(newState.copyWith(inputUnit: unit));
    } else {
      final newState = _onInputVariableUpdate(unit: unit);
      state = AsyncValue.data(newState.copyWith(inputUnit: unit));
    }
  }

  void setType(AquaAssetInputType type) {
    final currentState = state.value!;

    if (type == currentState.inputType) return;

    final service = ref.read(amountInputServiceProvider);
    final newBalanceDisplay = service.getBalanceDisplay(
      balanceInSats: currentState.balanceInSats,
      type: type,
      unit: type == AquaAssetInputType.crypto
          ? currentState.inputUnit
          : AquaAssetInputUnit.crypto,
      rate: currentState.rate,
      asset: currentState.asset,
    );

    if (currentState.amountInSats == 0) {
      final symbol = currentState.rate.currency.format.symbol;
      final conversionAmount = type == AquaAssetInputType.crypto
          ? '${symbol}0.00'
          : service.getBalanceDisplay(
              balanceInSats: 0,
              type: AquaAssetInputType.crypto,
              unit: currentState.inputUnit,
              rate: currentState.rate,
              asset: currentState.asset,
            );

      state = AsyncValue.data(currentState.copyWith(
        inputType: type,
        inputUnit: type == AquaAssetInputType.crypto
            ? currentState.inputUnit
            : AquaAssetInputUnit.crypto,
        amountFieldText: null,
        displayConversionAmount: conversionAmount,
        balanceDisplay: newBalanceDisplay,
      ));
      return;
    }

    String? convertedText;
    if (type == AquaAssetInputType.fiat) {
      if (currentState.asset.isUSDt) {
        convertedText = ref.read(amountInputServiceProvider).formatUsdtAmount(
              amountInSats: currentState.amountInSats,
              asset: currentState.asset,
              targetCurrency: currentState.rate.currency,
              currencyFormat: currentState.rate.currency.format,
              withSymbol: false,
            );
      } else {
        final fiatRate = ref
                .read(fiatRatesProvider)
                .valueOrNull
                ?.firstWhereOrNull(
                    (r) => r.code == currentState.rate.currency.value)
                ?.rate ??
            0;
        if (fiatRate > 0) {
          final fiatAmount = currentState.amountInSats /
              SupportedDisplayUnits.btc.satsPerUnit *
              fiatRate;
          convertedText = fiatAmount.toString();
        }
      }
    } else {
      final displayUnit =
          SupportedDisplayUnits.fromAssetInputUnit(currentState.inputUnit);
      final decimal = ref.read(displayUnitsProvider).convertSatsToUnit(
            sats: currentState.amountInSats,
            asset: currentState.asset,
            displayUnitOverride: displayUnit,
          );
      convertedText = decimal.toString();
    }

    final newState = _onInputVariableUpdate(
      type: type,
      text: convertedText,
    );
    state = AsyncValue.data(newState.copyWith(
      inputType: type,
      inputUnit: type == AquaAssetInputType.crypto
          ? currentState.inputUnit
          : AquaAssetInputUnit.crypto,
      balanceDisplay: newBalanceDisplay,
    ));
  }

  String setTypeAndGetControllerText(AquaAssetInputType type) {
    setType(type);
    final currentState = state.value!;
    return currentState.amountInSats == 0
        ? ''
        : (currentState.amountFieldText ?? '');
  }

  // Helper method to extract raw numeric value from formatted text

  void submitAmount() {
    final value = state.value!;
    // Value comes in sats so typing 1 means 10^8 sats.
    // That applies to all assets.

    if (arg.asset.isNonSatsAsset) {
      ref.read(receiveAssetAmountProvider.notifier).state =
          encodeBip21AmountFromSats(
        amountInSats: value.amountInSats,
        asset: arg.asset,
      );
    } else {
      ref.read(receiveAssetAmountProvider.notifier).state =
          value.amountInSats.toString();
    }
  }

  void clearInput() {
    final currentState = state.value!;
    final symbol =
        ref.read(exchangeRatesProvider).currentCurrency.currency.format.symbol;

    final service = ref.read(amountInputServiceProvider);
    final conversionAmount = currentState.inputType == AquaAssetInputType.crypto
        ? '${symbol}0.00'
        : service.getBalanceDisplay(
            balanceInSats: 0,
            type: AquaAssetInputType.crypto,
            unit: currentState.inputUnit,
            rate: ref.read(exchangeRatesProvider).currentCurrency,
            asset: currentState.asset,
          );

    state = AsyncValue.data(state.value!.copyWith(
      amountFieldText: null,
      amountInSats: 0,
      displayConversionAmount: conversionAmount,
    ));
  }

  ReceiveAmountInputState _onInputVariableUpdate({
    String? text,
    AquaAssetInputType? type,
    ExchangeRate? rate,
    AquaAssetInputUnit? unit,
  }) {
    final asset = state.value!.asset;
    final balanceInSats = state.value!.balanceInSats;
    text ??= state.value!.amountFieldText ?? '0';
    type ??= state.value!.inputType;
    rate ??= state.value!.rate;
    unit ??= state.value!.inputUnit;

    final service = ref.read(amountInputServiceProvider);
    final result = service.processAmountInput(
      text: text,
      type: type,
      unit: unit,
      rate: rate,
      asset: asset,
      balanceInSats: balanceInSats,
      currentStateRate: state.value!.rate,
    );

    final fallbackConversionAmount = result.displayConversionAmount ??
        (type == AquaAssetInputType.crypto
            ? '${rate.currency.format.symbol}0.00'
            : service.getBalanceDisplay(
                balanceInSats: 0,
                type: AquaAssetInputType.crypto,
                unit: unit,
                rate: rate,
                asset: asset,
              ));

    return state.value!.copyWith(
      amountFieldText: result.formattedAmountText,
      amountInSats: result.amountInSats,
      balanceInSats: balanceInSats,
      balanceDisplay: result.balanceDisplay,
      displayConversionAmount: fallbackConversionAmount,
    );
  }
}
