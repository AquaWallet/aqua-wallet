import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_rate.freezed.dart';
part 'exchange_rate.g.dart';

enum FiatCurrency {
  usd('USD', '\$'),
  eur('EUR', '€'),
  cad('CAD', '\$'),
  gbp('GBP', '£'),
  mxn('MXN', 'Mex\$'),
  aud('AUD', '\$'),
  brl('BRL', 'R\$'),
  chf('CHF', 'CHF'),
  clp('CLP', '\$'),
  cny('CNY', '¥'),
  czk('CZK', 'Kč'),
  dkk('DKK', 'kr.'),
  hkd('HKD', '\$'),
  huf('HUF', 'Ft'),
  inr('INR', '₹'),
  isk('ISK', 'kr'),
  jpy('JPY', '¥'),
  krw('KRW', '₩'),
  nzd('NZD', '\$'),
  pln('PLN', 'zł'),
  ron('RON', 'lei'),
  rub('RUB', '₽'),
  sek('SEK', 'kr'),
  sgd('SGD', '\$'),
  thb('THB', '฿'),
  turkishLira('TRY', '₺'),
  twd('TWD', '\$'),
  ils('ILS', '₪'),
  ars('ARS', '\$'),
  ngn('NGN', '₦'),
  lbp('LBP', 'ل.ل'),
  myr('MYR', 'RM'),
  vnd('VND', '₫'),
  zar('ZAR', 'R'),
  nok('NOK', 'kr');

  const FiatCurrency(this.value, [this.symbol = '']);

  final String value;
  final String symbol;

  String toStringWithSymbol() => '$value ($symbol)';
}

String currencyLabelLookup(FiatCurrency currency, BuildContext context) {
  final label = switch (currency) {
    FiatCurrency.usd => context.loc.settingsScreenCurrencyLabelUSD,
    FiatCurrency.eur => context.loc.settingsScreenCurrencyLabelEUR,
    FiatCurrency.cad => context.loc.settingsScreenCurrencyLabelCAD,
    FiatCurrency.gbp => context.loc.settingsScreenCurrencyLabelGBP,
    FiatCurrency.chf => context.loc.settingsScreenCurrencyLabelCHF,
    FiatCurrency.aud => context.loc.settingsScreenCurrencyLabelAUD,
    FiatCurrency.brl => context.loc.settingsScreenCurrencyLabelBRL,
    FiatCurrency.cny => context.loc.settingsScreenCurrencyLabelCNY,
    FiatCurrency.czk => context.loc.settingsScreenCurrencyLabelCZK,
    FiatCurrency.dkk => context.loc.settingsScreenCurrencyLabelDKK,
    FiatCurrency.hkd => context.loc.settingsScreenCurrencyLabelHKD,
    FiatCurrency.ils => context.loc.settingsScreenCurrencyLabelILS,
    FiatCurrency.inr => context.loc.settingsScreenCurrencyLabelINR,
    FiatCurrency.jpy => context.loc.settingsScreenCurrencyLabelJPY,
    FiatCurrency.mxn => context.loc.settingsScreenCurrencyLabelMXN,
    FiatCurrency.myr => context.loc.settingsScreenCurrencyLabelMYR,
    FiatCurrency.ngn => context.loc.settingsScreenCurrencyLabelNGN,
    FiatCurrency.nok => context.loc.settingsScreenCurrencyLabelNOK,
    FiatCurrency.nzd => context.loc.settingsScreenCurrencyLabelNZD,
    FiatCurrency.pln => context.loc.settingsScreenCurrencyLabelPLN,
    FiatCurrency.rub => context.loc.settingsScreenCurrencyLabelRUB,
    FiatCurrency.sek => context.loc.settingsScreenCurrencyLabelSEK,
    FiatCurrency.sgd => context.loc.settingsScreenCurrencyLabelSGD,
    FiatCurrency.thb => context.loc.settingsScreenCurrencyLabelTHB,
    FiatCurrency.turkishLira => context.loc.settingsScreenCurrencyLabelTRY,
    FiatCurrency.vnd => context.loc.settingsScreenCurrencyLabelVND,
    FiatCurrency.zar => context.loc.settingsScreenCurrencyLabelZAR,
    _ => currency.symbol
  };

  return label;
}

enum ExchangeRateSource {
  bitfinex('BITFINEX'),
  bitstamp('BITSTAMP'),
  kraken('KRAKEN'),
  coingecko('COINGECKO'),
  bullbitcoin('BULLBITCOIN');

  const ExchangeRateSource(this.value);

  final String value;
}

class ExchangeRate {
  final FiatCurrency currency;
  final ExchangeRateSource source;

  String displayName(BuildContext context) {
    final label = currencyLabelLookup(currency, context);
    final signAndCode = currency.symbol != currency.value
        ? '(${currency.symbol} ${currency.value})'
        : '(${currency.symbol})';
    return '$label $signAndCode';
  }

  const ExchangeRate(this.currency, this.source);
}

@freezed
class BitcoinFiatRatesResponse with _$BitcoinFiatRatesResponse {
  const factory BitcoinFiatRatesResponse({
    required String name,
    required String cryptoCode,
    required String currencyPair,
    required String code,
    required double rate,
  }) = _BitcoinFiatRatesResponse;

  factory BitcoinFiatRatesResponse.fromJson(Map<String, dynamic> json) =>
      _$BitcoinFiatRatesResponseFromJson(json);
}
