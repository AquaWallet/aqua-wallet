import 'dart:math';

import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';

final reRemoveTrailingDecimals = RegExp(r"\.0+$|(\.\d*[1-9])(0+)$");

final formatterProvider =
    Provider.autoDispose<FormatterProvider>(FormatterProvider.new);

class FormatterProvider {
  FormatterProvider(this._ref);

  static const int _kCoin = 100000000;

  final AutoDisposeRef _ref;

  String formatAssetAmountFromAsset({
    required Asset asset,
    bool separated = true,
  }) {
    return formatAssetAmount(
      amount: asset.amount,
      precision: asset.precision,
      separated: separated,
    );
  }

  String formatAssetAmount({
    required int amount,
    int? precision,
    bool separated = true,
  }) {
    return formatAssetAmountDirect(
      amount: amount,
      precision: precision,
      separated: separated,
    );
  }

  String formatAssetAmountDirect({
    required int amount,
    int? precision,
    bool separated = true,
  }) {
    precision ??= 8;
    final bitAmount = amount ~/ _kCoin;
    final satAmount = amount % _kCoin;
    final satAmountStr = satAmount.toString().padLeft(8, '0');
    final newAmount = Decimal.parse('$bitAmount$satAmountStr');
    final power = Decimal.parse(pow(10, precision).toStringAsFixed(precision));
    final amountWithPrecision = newAmount / power;

    final formatter = _ref.watch(currencyFormatProvider(precision));
    final formattedNumber = formatter.format(amountWithPrecision.toDouble());

    return formattedNumber.replaceAllMapped(
        reRemoveTrailingDecimals, (e) => e.group(1) ?? '');
  }

  String formatAmountDirect({
    required double amount,
    int precision = 8,
  }) {
    return _ref
        .watch(currencyFormatProvider(precision))
        .format(amount)
        .replaceAllMapped(reRemoveTrailingDecimals, (e) => e.group(1) ?? '');
  }

  String signedFormatAssetAmountFromAsset({required Asset asset}) {
    return signedFormatAssetAmount(
        amount: asset.amount, precision: asset.precision);
  }

  String signedFormatAssetAmount({
    required int amount,
    int? precision,
  }) {
    final formattedAmount = formatAssetAmount(
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
