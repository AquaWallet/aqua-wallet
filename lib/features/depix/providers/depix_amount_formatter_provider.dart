// DePix amount display uses Eulen gross/net cents from the fee API as the source
// of truth, not local rate or fee math. Shared amount-entry helpers (e.g.
// amountEntryComputeLines) always derive conversion from what the user typed, so
// they would show wrong values once backend fees apply.
import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/depix/models/depix_models.dart';
import 'package:aqua/features/shared/services/amount_input_service.dart';
import 'package:aqua/features/settings/exchange_rate/models/exchange_rate.dart';
import 'package:decimal/decimal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const depixAssetTicker = 'DePix';
const depixBrlFormat = FiatCurrency.brl;

class DepixAmountFormatter {
  const DepixAmountFormatter(this._format, this._amountInputService);

  final FormatService _format;
  final AmountInputService _amountInputService;

  String formatBrlCents(int cents, {bool withSymbol = false}) {
    return _formatFiatNumeric(
      _decimalFromBrlCents(cents),
      depixBrlFormat.format,
      withSymbol: withSymbol,
    );
  }

  String fieldTextFromBrlCents(int cents) {
    if (cents <= 0) return '';
    return formatBrlCents(cents);
  }

  String? conversionLine({
    required bool isReversed,
    required int netAmountBrlCents,
    required int grossAmountBrlCents,
  }) {
    final fiatSpec = depixBrlFormat.format;
    if (!isReversed) {
      final body = _formatFiatNumeric(
        _decimalFromBrlCents(netAmountBrlCents),
        _noSymbolSpec(fiatSpec),
      );
      return '~ $body $depixAssetTicker';
    }
    final brl = formatBrlCents(grossAmountBrlCents, withSymbol: true);
    return '~ $brl';
  }

  String primaryLine({
    required bool isReversed,
    required String rawFieldText,
  }) {
    final fiatSpec = depixBrlFormat.format;
    final raw = rawFieldText.trim();
    final isEmpty = raw.isEmpty;

    if (!isReversed) {
      if (isEmpty) {
        return _format.formatFiatAmount(
          amount: Decimal.zero,
          specOverride: fiatSpec,
          withSymbol: true,
        );
      }
      final body = _amountInputService.getFormattedAmountFieldTextForSpec(
            amountFieldText: raw,
            fiatSpec: fiatSpec,
          ) ??
          raw;
      return _fiatPrimaryWithSymbol(body, fiatSpec);
    }

    if (isEmpty) {
      final zero = _format.formatFiatAmount(
        amount: Decimal.zero,
        specOverride: _noSymbolSpec(fiatSpec),
        withSymbol: false,
      );
      return '$zero $depixAssetTicker';
    }
    final body = _amountInputService.getFormattedAmountFieldTextForSpec(
          amountFieldText: raw,
          fiatSpec: fiatSpec,
        ) ??
        raw;
    return '$body $depixAssetTicker';
  }

  String swapFieldText(EulenFeeCalculation calc, bool isReversedBefore) {
    final cents =
        isReversedBefore ? calc.grossAmountBrlCents : calc.netAmountBrlCents;
    return fieldTextFromBrlCents(cents);
  }

  String _formatFiatNumeric(
    Decimal amount,
    CurrencyFormatSpec spec, {
    bool withSymbol = false,
  }) {
    final max = spec.decimalPlaces;
    final dp = amount == Decimal.zero
        ? max
        : (amount.scale > max ? max : amount.scale);
    return _format.formatFiatAmount(
      amount: amount,
      specOverride: spec,
      withSymbol: withSymbol,
      decimalPlacesOverride: dp,
    );
  }

  CurrencyFormatSpec _noSymbolSpec(CurrencyFormatSpec s) => CurrencyFormatSpec(
        symbol: '',
        isSymbolLeading: s.isSymbolLeading,
        thousandsSeparator: s.thousandsSeparator,
        decimalSeparator: s.decimalSeparator,
        decimalPlaces: s.decimalPlaces,
        currencyCountryCode: s.currencyCountryCode,
      );

  Decimal _decimalFromBrlCents(int cents) =>
      Decimal.parse((cents / 100).toString());

  String _fiatPrimaryWithSymbol(String body, CurrencyFormatSpec spec) {
    if (spec.isSymbolLeading) return '${spec.symbol}$body';
    return '$body ${spec.symbol}';
  }
}

final depixAmountFormatterProvider =
    Provider.autoDispose<DepixAmountFormatter>((ref) {
  return DepixAmountFormatter(
    ref.watch(formatProvider),
    ref.watch(amountInputServiceProvider),
  );
});
