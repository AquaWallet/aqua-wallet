import 'dart:math';

import 'package:aqua/common/common.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:decimal/decimal.dart';
import 'package:ui_components/ui_components.dart';

final amountInputServiceProvider =
    Provider.autoDispose((ref) => AmountInputService(
          formatterProvider: ref.watch(formatterProvider),
          formatProvider: ref.watch(formatProvider),
          fiatRatesProvider: ref.watch(fiatRatesProvider),
          unitsProvider: ref.watch(displayUnitsProvider),
        ));

/// Service class that handles common amount input calculations and formatting
/// for both send and receive flows.
class AmountInputService {
  const AmountInputService({
    required this.formatterProvider,
    required this.formatProvider,
    required this.fiatRatesProvider,
    required this.unitsProvider,
  });

  final FormatterProvider formatterProvider;
  final FormatService formatProvider;
  final DisplayUnitsProvider unitsProvider;
  final AsyncValue<List<BitcoinFiatRatesResponse>> fiatRatesProvider;

  /// Calculates the fiat conversion rate for a given amount
  String getFiatConversionRate({
    required String amountText,
    required ExchangeRate rate,
    required AquaAssetInputUnit unit,
    required AquaAssetInputType type,
    required Asset asset,
  }) {
    final symbol = rate.currency.format.symbol;
    final defaultRate = '${symbol}0.00';
    if (!asset.hasFiatRate) return defaultRate;

    // USDt assets don't need fiat conversion since they're already USD-pegged
    if (asset.isUSDt && type == AquaAssetInputType.fiat) return defaultRate;

    final fiatRate = fiatRatesProvider.valueOrNull
            ?.firstWhereOrNull((r) => r.code == rate.currency.value)
            ?.rate ??
        0;

    if (type == AquaAssetInputType.crypto) {
      final displayUnit = SupportedDisplayUnits.fromAssetInputUnit(unit);
      final precision = asset.isBTC || asset.isLBTC || asset.isLightning
          ? displayUnit.getDisplayPrecision(asset)
          : asset.precision;

      final sats = formatterProvider.parseAssetAmountToSats(
        amount: amountText,
        asset: asset,
        precision: precision,
        forcedDisplayUnit: displayUnit,
      );
      final fiatAmount =
          sats / SupportedDisplayUnits.btc.satsPerUnit * fiatRate;
      return formatProvider.formatFiatAmount(
        amount: DecimalExt.fromDouble(fiatAmount),
        specOverride: rate.currency.format,
        withSymbol: true,
      );
    } else {
      final amount = double.tryParse(amountText) ?? 0;

      return switch (unit) {
        AquaAssetInputUnit.crypto => fiatRate != 0
            ? (amount / fiatRate).toStringAsFixed(asset.precision)
            : defaultRate,
        _ => amountText,
      };
    }
  }

  /// Calculates the balance display for a given type and unit
  String getBalanceDisplay({
    required int balanceInSats,
    required AquaAssetInputType type,
    required AquaAssetInputUnit unit,
    required ExchangeRate rate,
    required Asset asset,
  }) {
    if (type == AquaAssetInputType.crypto) {
      return formatProvider.formatAssetAmount(
        asset: asset,
        amount: balanceInSats,
        displayUnitOverride: SupportedDisplayUnits.fromAssetInputUnit(unit),
      );
    } else {
      // USDt is 1:1 with USD, convert to target currency
      if (asset.isUSDt) {
        return formatUsdtAmount(
          amountInSats: balanceInSats,
          asset: asset,
          targetCurrency: rate.currency,
          currencyFormat: rate.currency.format,
        );
      }

      // For other assets, convert via BTC exchange rate
      final fiatRate = fiatRatesProvider.valueOrNull
              ?.firstWhereOrNull((r) => r.code == rate.currency.value)
              ?.rate ??
          0;
      final balanceInBtc =
          balanceInSats / SupportedDisplayUnits.btc.satsPerUnit;
      final balanceInFiat = balanceInBtc * fiatRate;
      return formatProvider.formatFiatAmount(
        amount: DecimalExt.fromDouble(balanceInFiat),
        specOverride: rate.currency.format,
        withSymbol: true,
      );
    }
  }

  /// Extracts raw numeric value from formatted text
  double extractRawValue({
    String? formattedText,
    required AquaAssetInputType currentType,
    required AquaAssetInputUnit currentUnit,
    required Asset asset,
    required ExchangeRate currentRate,
  }) {
    if (formattedText == null || formattedText.isEmpty) return 0;

    if (currentType == AquaAssetInputType.crypto) {
      final displayUnit = SupportedDisplayUnits.fromAssetInputUnit(currentUnit);
      final precision = asset.isBTC || asset.isLBTC || asset.isLightning
          ? displayUnit.getDisplayPrecision(asset)
          : asset.precision;

      final satsAmount = formatterProvider.parseAssetAmountToSats(
        amount: formattedText,
        precision: precision,
        asset: asset,
        forcedDisplayUnit: displayUnit,
      );

      final cryptoDecimal = unitsProvider.convertSatsToUnit(
        sats: satsAmount,
        asset: asset,
        displayUnitOverride: SupportedDisplayUnits.btc,
      );

      return cryptoDecimal.toDouble();
    } else {
      final cleanText = formatterProvider.cleanAmountString(
        formattedText,
        currentRate.currency.format,
      );
      return double.tryParse(cleanText) ?? 0;
    }
  }

  /// Processes amount input and returns formatted amounts and satoshi value
  AmountInputResult processAmountInput({
    required String text,
    required AquaAssetInputType type,
    required AquaAssetInputUnit unit,
    required ExchangeRate rate,
    required Asset asset,
    required int balanceInSats,
    ExchangeRate? currentStateRate,
  }) {
    final balanceDisplay = getBalanceDisplay(
      balanceInSats: balanceInSats,
      type: type,
      unit: unit,
      rate: rate,
      asset: asset,
    );

    if (type == AquaAssetInputType.crypto) {
      final displayUnit = SupportedDisplayUnits.fromAssetInputUnit(unit);
      final precision = asset.isBTC || asset.isLBTC || asset.isLightning
          ? displayUnit.getDisplayPrecision(asset)
          : asset.precision;

      final amountInSats = formatterProvider.parseAssetAmountToSats(
        amount: text,
        asset: asset,
        precision: precision,
        forcedDisplayUnit: displayUnit,
      );

      final formattedAmountText = formatProvider.formatAssetAmount(
        asset: asset,
        amount: amountInSats,
        displayUnitOverride: SupportedDisplayUnits.fromAssetInputUnit(unit),
      );

      final displayConversionAmount = amountInSats == 0 || asset.isNonSatsAsset
          ? null
          : getFiatConversionRate(
              amountText: text,
              rate: rate,
              unit: unit,
              type: type,
              asset: asset,
            );

      return AmountInputResult(
        formattedAmountText: formattedAmountText,
        amountInSats: amountInSats,
        balanceDisplay: balanceDisplay,
        displayConversionAmount: displayConversionAmount,
      );
    } else {
      // Use FormatterProvider's locale-aware cleaning for fiat amounts
      // IMPORTANT: Use current state's currency format, not the passed rate
      // (which might be new currency)
      // However, if text is already a simple numeric string (like from setRate),
      // don't over-clean
      final amount = double.tryParse(text);
      final cleanText = amount != null
          ? text
          : formatterProvider.cleanAmountString(
              text,
              currentStateRate?.currency.format ?? rate.currency.format,
            );
      final finalAmount = amount ?? (double.tryParse(cleanText) ?? 0);

      final int amountInSats;
      // Non-sats assets (USDT, EURx, etc.) are 1:1, parse using asset precision
      if (asset.isNonSatsAsset) {
        amountInSats = _parseNonSatsAmount(
          fiatAmount: finalAmount,
          asset: asset,
          sourceCurrency: rate.currency,
        );
      } else {
        final fiatRate = fiatRatesProvider.valueOrNull
                ?.firstWhereOrNull((r) => r.code == rate.currency.value)
                ?.rate ??
            0;
        amountInSats = fiatRate > 0
            ? (finalAmount / fiatRate * SupportedDisplayUnits.btc.satsPerUnit)
                .toInt()
            : 0;
      }

      // Format amountFieldText in fiat style with proper decimal separator
      final formattedAmountText = formatProvider.formatFiatAmount(
        amount: DecimalExt.fromDouble(finalAmount),
        specOverride: rate.currency.format,
        withSymbol: false,
      );

      final displayConversionAmount = amountInSats == 0 || asset.isUSDt
          ? null
          : formatProvider.formatAssetAmount(
              asset: asset,
              amount: amountInSats,
              displayUnitOverride:
                  SupportedDisplayUnits.fromAssetInputUnit(unit),
            );

      return AmountInputResult(
        formattedAmountText: formattedAmountText,
        amountInSats: amountInSats,
        balanceDisplay: balanceDisplay,
        displayConversionAmount: displayConversionAmount,
      );
    }
  }

  // Formats amount field to add thousands separators and decimal separator
  String? getFormattedAmountFieldText({
    String? amountFieldText,
    required ExchangeRate rate,
  }) {
    final text = amountFieldText;

    if (text == null || text.isEmpty) return amountFieldText;

    final lastChar = text[text.length - 1];
    final endsWithSeparator = !RegExp(r'\d').hasMatch(lastChar);

    if (endsWithSeparator) {
      // Parse only the integer part of the text.
      final numberPart = text.substring(0, text.length - 1);
      final separator = rate.currency.format.decimalSeparator;
      if (numberPart.isEmpty) return '0$separator';

      final cleaned =
          formatterProvider.cleanAmountString(numberPart, rate.currency.format);
      final decimalValue = Decimal.tryParse(cleaned);
      if (decimalValue == null) return text;

      final formatted = formatProvider.formatFiatAmount(
          amount: decimalValue,
          specOverride: rate.currency.format,
          decimalPlacesOverride: 0,
          withSymbol: false);

      return '$formatted$separator';
    }

    final cleaned =
        formatterProvider.cleanAmountString(text, rate.currency.format);
    if (cleaned == '0') return cleaned;

    final decimalValue = Decimal.tryParse(cleaned);
    if (decimalValue == null) return text;

    // Get the decimal places to preserve them when formatting the amount.
    final parts = cleaned.split('.');
    final decimalPlaces = parts.length > 1 ? parts[1].length : 0;

    final value = formatProvider.formatFiatAmount(
        amount: decimalValue,
        specOverride: rate.currency.format,
        decimalPlacesOverride: decimalPlaces,
        withSymbol: false);

    return value;
  }

  /// Formats USDt amount in target currency
  ///
  /// Converts USDt sats to USD, then to target currency if needed.
  /// Supports both balance display (with symbol) and error messages (without symbol).
  String formatUsdtAmount({
    required int amountInSats,
    required Asset asset,
    required FiatCurrency targetCurrency,
    required CurrencyFormatSpec currencyFormat,
    bool withSymbol = true,
  }) {
    final usdAmount = amountInSats / pow(10, asset.precision);

    // If USD, no conversion needed
    if (targetCurrency.isUsd) {
      return formatProvider.formatFiatAmount(
        amount: DecimalExt.fromDouble(usdAmount),
        specOverride: currencyFormat,
        withSymbol: withSymbol,
      );
    }

    // Convert to target currency
    final conversionRate = _getUsdToTargetCurrencyRate(targetCurrency);
    final targetAmount =
        conversionRate != null ? usdAmount * conversionRate : usdAmount;

    return formatProvider.formatFiatAmount(
      amount: DecimalExt.fromDouble(targetAmount),
      specOverride: currencyFormat,
      withSymbol: withSymbol,
    );
  }

  /// Parses USDt amount from fiat input, converting if needed
  int _parseUsdtAmount({
    required double fiatAmount,
    required Asset asset,
    required FiatCurrency sourceCurrency,
  }) {
    double usdAmount = fiatAmount;

    // If not USD, convert from source currency to USD
    if (!sourceCurrency.isUsd) {
      final conversionRate = _getTargetCurrencyToUsdRate(sourceCurrency);
      if (conversionRate != null) {
        usdAmount = fiatAmount * conversionRate;
      }
    }

    // Convert USD to USDt sats
    return (usdAmount * pow(10, asset.precision)).toInt();
  }

  /// Parses non-sats asset amount (USDT, EURx, etc.) from fiat input
  /// These assets are 1:1 with their pegged currency, so we multiply by precision directly
  int _parseNonSatsAmount({
    required double fiatAmount,
    required Asset asset,
    required FiatCurrency sourceCurrency,
  }) {
    if (asset.isUSDt) {
      return _parseUsdtAmount(
        fiatAmount: fiatAmount,
        asset: asset,
        sourceCurrency: sourceCurrency,
      );
    }

    // For other non-sats assets (EURx, etc.), treat as 1:1 with input currency
    // Multiply by asset precision to get internal representation, and return as int
    return (fiatAmount *
            DecimalExt.fromAssetPrecision(asset.precision).toDouble())
        .toInt();
  }

  /// Gets conversion rate from USD to target currency using BTC rates
  double? _getUsdToTargetCurrencyRate(FiatCurrency targetCurrency) {
    final rates = fiatRatesProvider.valueOrNull;
    if (rates == null) return null;

    final targetRate =
        rates.firstWhereOrNull((r) => r.code == targetCurrency.value)?.rate;
    final usdRate = rates.firstWhereOrNull((r) => r.isUsd)?.rate;

    if (targetRate == null || usdRate == null || usdRate == 0) return null;

    return targetRate / usdRate;
  }

  /// Gets conversion rate from target currency to USD using BTC rates
  double? _getTargetCurrencyToUsdRate(FiatCurrency sourceCurrency) {
    final rates = fiatRatesProvider.valueOrNull;
    if (rates == null) return null;

    final sourceRate =
        rates.firstWhereOrNull((r) => r.code == sourceCurrency.value)?.rate;
    final usdRate = rates.firstWhereOrNull((r) => r.isUsd)?.rate;

    if (sourceRate == null || usdRate == null || sourceRate == 0) return null;

    return usdRate / sourceRate;
  }
}

/// Result of amount input processing
class AmountInputResult {
  const AmountInputResult({
    required this.formattedAmountText,
    required this.amountInSats,
    required this.balanceDisplay,
    required this.displayConversionAmount,
  });

  final String formattedAmountText;
  final int amountInSats;
  final String balanceDisplay;
  final String? displayConversionAmount;
}
