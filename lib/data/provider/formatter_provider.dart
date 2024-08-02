import 'dart:math';

import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';

final reRemoveTrailingDecimals = RegExp(r"\.0+$|(\.\d*[1-9])(0+)$");

final formatterProvider =
    Provider.autoDispose<FormatterProvider>(FormatterProvider.new);

class FormatterProvider {
  FormatterProvider(this._ref);

  final AutoDisposeRef _ref;

  String convertAssetAmountToDisplayUnit({
    required int amount,
    required int precision,
  }) {
    final amountWithPrecision = Decimal.parse(amount.toString()) /
        Decimal.parse(pow(10, precision).toString());
    return amountWithPrecision.toDecimal().toString();
  }

  String formatAssetAmountDirect({
    required int amount,
    required int precision,
    int? roundingOverride,
    bool removeTrailingZeros = true,
  }) {
    final amountWithPrecision = Decimal.parse(amount.toString()) /
        Decimal.parse(pow(10, precision).toString());
    final formatter =
        _ref.watch(currencyFormatProvider(roundingOverride ?? precision));
    final formattedNumber = formatter.format(amountWithPrecision.toDouble());
    return removeTrailingZeros
        ? formattedNumber.replaceAllMapped(
            reRemoveTrailingDecimals, (e) => e.group(1) ?? '')
        : formattedNumber;
  }

  String signedFormatAssetAmount({
    required int amount,
    required int precision,
  }) {
    final formattedAmount = formatAssetAmountDirect(
      amount: amount.abs(),
      precision: precision,
    );
    if (amount >= 0) {
      return '+$formattedAmount';
    } else {
      return '-$formattedAmount';
    }
  }

  Future<int> parseAssetAmount(
      {required String amount, required int precision}) async {
    return parseAssetAmountDirect(amount: amount, precision: precision);
  }

  int parseAssetAmountDirect({required String amount, required int precision}) {
    if (precision < 0 || precision > 8) {
      throw ParseAmountWrongPrecissionException();
    }

    final replacedAmount = amount.replaceAll(' ', '');
    final amountWithPrecision =
        Decimal.tryParse(replacedAmount)?.toStringAsFixed(precision);
    if (amountWithPrecision == null) {
      throw ParseAmountUnableParseFromStringWithPrecisionException();
    }

    final newAmount = Decimal.tryParse(amountWithPrecision);

    if (newAmount == null) {
      throw ParseAmountUnableParseFromStringException();
    }

    final amountDec = newAmount * Decimal.fromInt(pow(10, precision).toInt());

    final amountInt = amountDec.toBigInt().toInt();

    if (Decimal.fromInt(amountInt) != amountDec) {
      throw ParseAmountIntNotEqualDecimalBaseException();
    }

    return amountInt;
  }
}

class ParseAmountWrongPrecissionException implements Exception {}

class ParseAmountUnableParseFromStringException implements Exception {}

class ParseAmountUnableParseFromStringWithPrecisionException
    implements Exception {}

class ParseAmountIntNotEqualDecimalBaseException implements Exception {}
