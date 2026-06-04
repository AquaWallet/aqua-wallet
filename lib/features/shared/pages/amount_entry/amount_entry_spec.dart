import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/settings/exchange_rate/models/exchange_rate.dart';
import 'package:aqua/features/shared/services/amount_input_service.dart';
import 'package:decimal/decimal.dart';

class AmountEntrySpec {
  const AmountEntrySpec({
    required this.fiat,
    required this.assetTicker,
    required this.assetPerFiatUnit,
    this.fixedFiatFee,
  });

  final FiatCurrency fiat;
  final String assetTicker;
  final double assetPerFiatUnit;
  final double? fixedFiatFee;
}

Decimal _rateDecimal(AmountEntrySpec spec) =>
    Decimal.parse(spec.assetPerFiatUnit.toString());

Decimal? _feeDecimal(AmountEntrySpec spec) {
  final fee = spec.fixedFiatFee;
  if (fee == null) return null;
  return Decimal.parse(fee.toString());
}

Decimal amountEntryFiatToAssetAmount(Decimal fiatInput, AmountEntrySpec spec) {
  final rate = _rateDecimal(spec);
  final fee = _feeDecimal(spec);
  final netFiat = fee == null
      ? fiatInput
      : (fiatInput - fee).clamp(Decimal.zero, fiatInput);
  return netFiat * rate;
}

Decimal amountEntryAssetToFiatAmount(Decimal assetInput, AmountEntrySpec spec) {
  final rate = _rateDecimal(spec);
  final scaled = (assetInput / rate).toDecimal();
  final fee = _feeDecimal(spec);
  return fee == null ? scaled : scaled + fee;
}

CurrencyFormatSpec amountEntryParseFormatSpec(
  AmountEntrySpec spec,
  String? decimalSeparatorOverride,
) {
  final base = spec.fiat.format;
  if (decimalSeparatorOverride == null) return base;
  return CurrencyFormatSpec(
    symbol: base.symbol,
    isSymbolLeading: base.isSymbolLeading,
    thousandsSeparator: base.thousandsSeparator,
    decimalSeparator: decimalSeparatorOverride,
    decimalPlaces: base.decimalPlaces,
    currencyCountryCode: base.currencyCountryCode,
  );
}

String amountEntryFormatFiatNumeric(
  FormatService format,
  Decimal amount,
  CurrencyFormatSpec spec, {
  required bool padZeroDecimals,
  bool withSymbol = false,
}) {
  if (padZeroDecimals) {
    return format.formatFiatAmount(
      amount: Decimal.zero,
      specOverride: spec,
      withSymbol: withSymbol,
    );
  }
  final max = spec.decimalPlaces;
  final dp =
      amount == Decimal.zero ? max : (amount.scale > max ? max : amount.scale);
  return format.formatFiatAmount(
    amount: amount,
    specOverride: spec,
    withSymbol: withSymbol,
    decimalPlacesOverride: dp,
  );
}

CurrencyFormatSpec amountEntryNoSymbolSpec(CurrencyFormatSpec s) =>
    CurrencyFormatSpec(
      symbol: '',
      isSymbolLeading: s.isSymbolLeading,
      thousandsSeparator: s.thousandsSeparator,
      decimalSeparator: s.decimalSeparator,
      decimalPlaces: s.decimalPlaces,
      currencyCountryCode: s.currencyCountryCode,
    );

String amountEntryTextAfterDirectionToggle(
  double amount,
  bool isReversedBefore,
  AmountEntrySpec spec,
  FormatService format,
) {
  if (amount == 0) return '';
  final amt = Decimal.parse(amount.toString());
  final d = !isReversedBefore
      ? amountEntryFiatToAssetAmount(amt, spec)
      : amountEntryAssetToFiatAmount(amt, spec);
  return amountEntryFormatFiatNumeric(
    format,
    d,
    spec.fiat.format,
    padZeroDecimals: false,
  );
}

({String primaryLine, String conversionLine}) amountEntryComputeLines({
  required FormatService format,
  required AmountInputService amountInputService,
  required AmountEntrySpec spec,
  required double inputAmount,
  required bool isReversed,
  required String rawFieldText,
}) {
  final fiatSpec = spec.fiat.format;
  final amt = Decimal.parse(inputAmount.toString());
  final raw = rawFieldText.trim();
  final isEmpty = raw.isEmpty;

  if (!isReversed) {
    final primary = isEmpty
        ? format.formatFiatAmount(
            amount: Decimal.zero,
            specOverride: fiatSpec,
            withSymbol: true,
          )
        : _fiatPrimaryWithSymbol(
            amountInputService.getFormattedAmountFieldTextForSpec(
                  amountFieldText: raw,
                  fiatSpec: fiatSpec,
                ) ??
                raw,
            fiatSpec,
          );
    final assetConverted = amountEntryFiatToAssetAmount(amt, spec);
    final convBody = amountEntryFormatFiatNumeric(
      format,
      assetConverted,
      amountEntryNoSymbolSpec(fiatSpec),
      padZeroDecimals: isEmpty,
    );
    return (
      primaryLine: primary,
      conversionLine: '~ $convBody ${spec.assetTicker}'
    );
  }

  final primary = isEmpty
      ? '${format.formatFiatAmount(amount: Decimal.zero, specOverride: amountEntryNoSymbolSpec(fiatSpec), withSymbol: false)} '
          '${spec.assetTicker}'
      : '${amountInputService.getFormattedAmountFieldTextForSpec(amountFieldText: raw, fiatSpec: fiatSpec) ?? raw} '
          '${spec.assetTicker}';
  final brl = amountEntryAssetToFiatAmount(amt, spec);
  final conv = amountEntryFormatFiatNumeric(
    format,
    brl,
    fiatSpec,
    padZeroDecimals: isEmpty,
    withSymbol: true,
  );
  return (primaryLine: primary, conversionLine: '~ $conv');
}

String _fiatPrimaryWithSymbol(String body, CurrencyFormatSpec spec) {
  if (spec.isSymbolLeading) return '${spec.symbol}$body';
  return '$body ${spec.symbol}';
}
