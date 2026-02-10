import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:decimal/decimal.dart';

final _thousandsSeparator = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
final _reRemoveTrailingDecimals = RegExp(r"\.0+$|(\.\d*[1-9])(0+)$");

final formatProvider = Provider.autoDispose<FormatService>((ref) {
  return FormatService(ref);
});

class FormatService {
  final Ref _ref;

  FormatService(this._ref);

  static const kBitcoinFractionalSeparator = '\u2009';

  /// Takes a [Decimal] amount and formats it according to the current or specified
  /// currency format settings, including proper thousands/decimal separators and
  /// currency symbols.
  ///
  /// Parameters:
  /// - [amount]: The decimal amount to format (e.g., 1234.56)
  /// - [specOverride]: Optional currency format specification to override the default
  /// - [decimalPlacesOverride]: Optional number of decimal places (default uses currency spec)
  /// - [withSymbol]: Whether to include the currency symbol (default: true)
  ///
  /// Returns a formatted string like "$1,234.56" or "1.234,56 €" depending on locale.
  String formatFiatAmount({
    required Decimal amount,
    CurrencyFormatSpec? specOverride,
    int? decimalPlacesOverride,
    bool withSymbol = true,
  }) {
    final spec = specOverride ??
        _ref.read(exchangeRatesProvider).currentCurrency.currency.format;
    final decimalPlaces = decimalPlacesOverride ?? spec.decimalPlaces;
    final formattedAmount = _formatDecimal(
      amount: amount.abs(),
      thousandsSeparator: spec.thousandsSeparator,
      decimalSeparator: spec.decimalSeparator,
      decimalPlaces: decimalPlaces,
    );

    final isNegative = amount < Decimal.zero;
    final signPrefix = isNegative ? '-' : '';

    if (!withSymbol) {
      return '$signPrefix$formattedAmount';
    }

    return spec.isSymbolLeading
        ? '$signPrefix${spec.symbol}$formattedAmount'
        : '$signPrefix$formattedAmount ${spec.symbol}';
  }

  /// Formats cryptocurrency amount from satoshis to string.
  ///
  /// Parameters:
  /// - [sats]: Amount in satoshis (for BTC/LBTC) or base units (for other assets)
  /// - [asset]: The cryptocurrency asset (BTC, LBTC, USDT, etc.)
  /// - [displayUnitOverride]: Optional display unit override (sats, bits, btc)
  /// - [specOverride]: Optional currency format specification override
  /// - [decimalPlacesOverride]: Optional decimal places override
  /// - [removeTrailingZeros]: Whether to remove trailing zeros (default: true)
  String formatAssetAmount({
    required int amount,
    required Asset asset,
    SupportedDisplayUnits? displayUnitOverride,
    CurrencyFormatSpec? specOverride,
    int? decimalPlacesOverride,
    bool removeTrailingZeros = true,
  }) {
    final unitsProvider = _ref.read(displayUnitsProvider);
    final displayUnit =
        displayUnitOverride ?? unitsProvider.getForcedDisplayUnit(asset);
    final spec = specOverride ??
        _ref.watch(exchangeRatesProvider).currentCurrency.currency.format;
    final convertedAmount = unitsProvider.convertSatsToUnit(
      sats: amount,
      asset: asset,
      displayUnitOverride: displayUnitOverride,
    );

    String formattedAmount;

    // formatting for btc, lbtc, and lightning
    if (asset.isBTC || asset.isLBTC || asset.isLightning) {
      formattedAmount = switch (displayUnit) {
        SupportedDisplayUnits.sats => _formatInteger(
            convertedAmount.toBigInt().toInt(), spec.thousandsSeparator),
        _ => _formatDecimal(
            amount: convertedAmount,
            thousandsSeparator: spec.thousandsSeparator,
            decimalSeparator: spec.decimalSeparator,
            decimalPlaces: displayUnit.displayPrecision,
            isBitcoin: true,
          ),
      };

      if (removeTrailingZeros && displayUnit != SupportedDisplayUnits.sats) {
        return formattedAmount.replaceAllMapped(
            _reRemoveTrailingDecimals, (e) => e.group(1) ?? '');
      }

      return formattedAmount;
    }

    formattedAmount = _formatDecimal(
      amount: convertedAmount,
      thousandsSeparator: spec.thousandsSeparator,
      decimalSeparator: spec.decimalSeparator,
      decimalPlaces: decimalPlacesOverride ?? asset.precision,
    );

    if (removeTrailingZeros) {
      return formattedAmount.replaceAllMapped(
          _reRemoveTrailingDecimals, (e) => e.group(1) ?? '');
    }

    return formattedAmount;
  }

  /// Formats cryptocurrency amount with optional sign prefix.
  /// Only shows '-' for negative amounts, no '+' for positive.
  String signedFormatAssetAmount({
    required int amount,
    required Asset asset,
    SupportedDisplayUnits? displayUnitOverride,
    int? decimalPlacesOverride,
    bool removeTrailingZeros = true,
  }) {
    final formattedAmount = formatAssetAmount(
      amount: amount.abs(),
      asset: asset,
      displayUnitOverride: displayUnitOverride,
      decimalPlacesOverride: decimalPlacesOverride,
      removeTrailingZeros: removeTrailingZeros,
    );
    if (amount < 0) {
      return '-$formattedAmount';
    } else {
      return formattedAmount;
    }
  }

  /// Formats cryptocurrency amount, returning null if amount or asset is null.
  String? formatAssetAmountOrElseNull({
    int? amount,
    Asset? asset,
    SupportedDisplayUnits? displayUnitOverride,
    CurrencyFormatSpec? specOverride,
    int? decimalPlacesOverride,
    bool removeTrailingZeros = true,
  }) {
    if (amount == null || asset == null || amount <= 0) {
      return null;
    }
    try {
      return formatAssetAmount(
        amount: amount,
        asset: asset,
        displayUnitOverride: displayUnitOverride,
        specOverride: specOverride,
        decimalPlacesOverride: decimalPlacesOverride,
        removeTrailingZeros: removeTrailingZeros,
      );
    } catch (e) {
      return null;
    }
  }

  String _formatDecimal({
    required Decimal amount,
    required String thousandsSeparator,
    required String decimalSeparator,
    required int decimalPlaces,
    bool isBitcoin = false,
  }) {
    try {
      final absAmount = amount.abs();
      final parts = absAmount.toStringAsFixed(decimalPlaces).split('.');
      final integerPart = parts[0];
      final formattedIntegerPart =
          _formatInteger(int.parse(integerPart), thousandsSeparator);

      if (parts.length == 1 || decimalPlaces == 0) {
        final result = formattedIntegerPart;
        return amount < Decimal.zero ? '-$result' : result;
      }

      var fractionalPartString = parts.length > 1
          ? parts[1].padRight(decimalPlaces, '0')
          : ''.padRight(decimalPlaces, '0');

      // Special formatting for Bitcoin with separators
      if (isBitcoin && decimalPlaces > 2 && decimalPlaces != 2) {
        var builtFractionalPart = '';
        builtFractionalPart = fractionalPartString.substring(0, 2);
        for (var i = 2; i < fractionalPartString.length; i += 3) {
          final end = i + 3 < fractionalPartString.length
              ? i + 3
              : fractionalPartString.length;
          builtFractionalPart += kBitcoinFractionalSeparator +
              fractionalPartString.substring(i, end);
        }
        fractionalPartString = builtFractionalPart.trimRight();
      }

      final result =
          '$formattedIntegerPart$decimalSeparator$fractionalPartString';
      return amount < Decimal.zero ? '-$result' : result;
    } catch (_) {
      return amount.toStringAsFixed(decimalPlaces);
    }
  }

  String _formatInteger(int value, String thousandsSeparator) {
    try {
      final valueStr = value.toString();
      if (thousandsSeparator.isEmpty) return valueStr;
      return valueStr.replaceAllMapped(
          _thousandsSeparator, (match) => '${match[1]}$thousandsSeparator');
    } catch (_) {
      return value.toString();
    }
  }
}

extension ConfirmationFormatter on FormatService {
  // Formats the confirmation count according to the current locale
  String formatConfirmations(AppLocalizations loc, int confirmationCount) {
    if (confirmationCount == 0) {
      return loc.noConfirmations;
    } else if (confirmationCount == 1) {
      return loc.oneConfirmation;
    } else if (confirmationCount > 6) {
      return loc.nConfirmations('6+');
    } else {
      final formattedCount = formatFiatAmount(
        amount: Decimal.fromInt(confirmationCount),
        decimalPlacesOverride: 0,
        withSymbol: false,
      );
      return loc.nConfirmations(formattedCount);
    }
  }
}
