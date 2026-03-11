import 'dart:math' as math;

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:decimal/decimal.dart';

final formatterProvider =
    Provider.autoDispose<FormatterProvider>(FormatterProvider.new);

class FormatterProvider {
  FormatterProvider(this._ref);

  final AutoDisposeRef _ref;

  /// Converts satoshi amount to input string for text fields
  String convertAssetAmountToDisplayUnit({
    required int amount,
    required Asset asset,
  }) {
    final unitsProvider = _ref.read(displayUnitsProvider);
    final convertedAmount = unitsProvider.convertSatsToUnit(
      sats: amount,
      asset: asset,
    );

    return convertedAmount.toString();
  }

  int parseAssetAmountDirect({required String amount, required int precision}) {
    if (precision < 0 || precision > 8) {
      throw ParseAmountWrongPrecisionException();
    }

    final replacedAmount = amount
        .replaceAll(' ', '')
        .replaceAll(FormatService.kBitcoinFractionalSeparator, '')
        .replaceAll(',', '');

    final amountWithPrecisionStr =
        Decimal.tryParse(replacedAmount)?.toStringAsFixed(precision);
    if (amountWithPrecisionStr == null) {
      throw ParseAmountUnableParseFromStringException(amount);
    }

    final newAmount = Decimal.tryParse(amountWithPrecisionStr);

    if (newAmount == null) {
      throw ParseAmountUnableParseFromStringException(amount);
    }

    final amountDec =
        newAmount * Decimal.fromInt(math.pow(10, precision).toInt());

    final amountInt = amountDec.toBigInt().toInt();

    if (Decimal.fromInt(amountInt) != amountDec) {
      throw ParseAmountIntNotEqualDecimalBaseException();
    }

    return amountInt;
  }

  int parseAssetAmountToSats({
    required String amount,
    required int precision,
    Asset? asset,
    SupportedDisplayUnits? forcedDisplayUnit,
  }) {
    final unitsProvider = _ref.read(displayUnitsProvider);
    final displayUnit =
        forcedDisplayUnit ?? unitsProvider.getForcedDisplayUnit(asset);
    final fiatSpec =
        _ref.read(exchangeRatesProvider).currentCurrency.currency.format;
    final cleanAmount = cleanAmountString(amount, fiatSpec);

    if (precision < 0 || precision > 8) {
      throw ParseAmountWrongPrecisionException();
    }

    if (asset?.isBTC == true ||
        asset?.isLBTC == true ||
        asset?.isLightning == true) {
      // For BTC parsing, we need to remove ALL types of spaces for Decimal.parse
      final decimalString = cleanAmount
          .replaceAll(' ', '') // regular space
          .replaceAll(
              FormatService.kBitcoinFractionalSeparator, '') // thin space
          .replaceAll('\u00A0', '') // non-breaking space
          .replaceAll('\u200B', ''); // zero-width space
      return unitsProvider.convertUnitToSats(
        amount: Decimal.parse(decimalString),
        asset: asset!,
        displayUnitOverride: displayUnit,
      );
    }

    // For non-BTC assets, also remove all types of spaces for parsing
    final decimalString = cleanAmount
        .replaceAll(' ', '') // regular space
        .replaceAll(FormatService.kBitcoinFractionalSeparator, '') // thin space
        .replaceAll('\u00A0', '') // non-breaking space
        .replaceAll('\u200B', ''); // zero-width space
    return parseAssetAmountDirect(amount: decimalString, precision: precision);
  }

  /// Cleans amount string using currency format specification
  String cleanAmountString(String amount, CurrencyFormatSpec spec) {
    var cleaned = amount
        .replaceAll(' ', '')
        .replaceAll(FormatService.kBitcoinFractionalSeparator, '');

    if (cleaned.isEmpty) return '0';

    // Get separators from currency spec
    final specDecimal = spec.decimalSeparator;
    final oppositeDecimal = specDecimal == '.' ? ',' : '.';

    // Handle cross-currency decimal separator detection
    // This fixes EUR/USD currency switch where users type "0,0001" with USD active
    if (cleaned.contains(specDecimal)) {
      // Input uses expected decimal separator - remove thousands separators
      cleaned = cleaned.replaceAll(spec.thousandsSeparator, '');
    } else if (cleaned.contains(oppositeDecimal)) {
      // Cross-currency case: check if opposite separator looks like decimal
      final parts = cleaned.split(oppositeDecimal);
      if (parts.length == 2 && parts[1].length <= 8 && parts[1].isNotEmpty) {
        // Short fractional part suggests decimal separator - convert to standard
        cleaned = cleaned.replaceAll(oppositeDecimal, '.');
      } else {
        // Long or multiple parts suggest thousands separator - remove
        cleaned = cleaned.replaceAll(oppositeDecimal, '');
      }
    }

    // Normalize to dot decimal separator for parsing
    if (specDecimal != '.') {
      cleaned = cleaned.replaceAll(specDecimal, '.');
    }

    return cleaned.isEmpty ? '0' : cleaned;
  }
}

class ParseAmountWrongPrecisionException implements Exception {}

class ParseAmountUnableParseFromStringException implements Exception {
  final String inputAmount;
  final StackTrace stackTrace;

  ParseAmountUnableParseFromStringException(this.inputAmount)
      : stackTrace = StackTrace.current;

  @override
  String toString() {
    return 'ParseAmountUnableParseFromStringException: Failed to parse "$inputAmount"\nStack trace: $stackTrace';
  }
}

class ParseAmountUnableParseFromStringWithPrecisionException
    implements Exception {}

class ParseAmountIntNotEqualDecimalBaseException implements Exception {}
