import 'package:aqua/features/settings/region/models/region.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_rate.freezed.dart';
part 'exchange_rate.g.dart';

class CurrencyFormatSpec {
  final String symbol;
  final bool isSymbolLeading;
  final String thousandsSeparator;
  final String decimalSeparator;
  final int decimalPlaces;
  final String currencyCountryCode;

  const CurrencyFormatSpec({
    this.symbol = '',
    this.isSymbolLeading = true,
    this.thousandsSeparator = ',',
    this.decimalSeparator = '.',
    this.decimalPlaces = 2,
    this.currencyCountryCode = 'US',
  });

  String get flagSvg => FlagHelper.getFlagPath(currencyCountryCode);
}

enum FiatCurrency {
  usd(
    'USD',
    CurrencyFormatSpec(
      symbol: '\$',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'US',
    ),
  ),
  eur(
    'EUR',
    CurrencyFormatSpec(
      symbol: '€',
      isSymbolLeading: true,
      thousandsSeparator: '.',
      decimalSeparator: ',',
      decimalPlaces: 2,
      currencyCountryCode: 'EU',
    ),
  ),
  cad(
    'CAD',
    CurrencyFormatSpec(
      symbol: '\$',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'CA',
    ),
  ),
  gbp(
    'GBP',
    CurrencyFormatSpec(
      symbol: '£',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'GB',
    ),
  ),
  chf(
    'CHF',
    CurrencyFormatSpec(
      symbol: 'CHF ',
      isSymbolLeading: true,
      thousandsSeparator: '\'',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'CH',
    ),
  ),
  aud(
    'AUD',
    CurrencyFormatSpec(
      symbol: '\$',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'AU',
    ),
  ),
  brl(
    'BRL',
    CurrencyFormatSpec(
      symbol: 'R\$ ',
      isSymbolLeading: true,
      thousandsSeparator: '.',
      decimalSeparator: ',',
      decimalPlaces: 2,
      currencyCountryCode: 'BR',
    ),
  ),
  cny(
    'CNY',
    CurrencyFormatSpec(
      symbol: '¥',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'CN',
    ),
  ),
  czk(
    'CZK',
    CurrencyFormatSpec(
      symbol: 'Kč',
      isSymbolLeading: false,
      thousandsSeparator: '\u2009\u2009',
      decimalSeparator: ',',
      decimalPlaces: 2,
      currencyCountryCode: 'CZ',
    ),
  ),
  dkk(
    'DKK',
    CurrencyFormatSpec(
      symbol: 'kr',
      isSymbolLeading: false,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'DK',
    ),
  ),
  hkd(
    'HKD',
    CurrencyFormatSpec(
      symbol: 'HK\$ ',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'HK',
    ),
  ),
  ils(
    'ILS',
    CurrencyFormatSpec(
      symbol: '₪',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'IL',
    ),
  ),
  inr(
    'INR',
    CurrencyFormatSpec(
      symbol: '₹',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'IN',
    ),
  ),
  jpy(
    'JPY',
    CurrencyFormatSpec(
      symbol: '¥',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'JP',
    ),
  ),
  mxn(
    'MXN',
    CurrencyFormatSpec(
      symbol: '\$',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'MX',
    ),
  ),
  myr(
    'MYR',
    CurrencyFormatSpec(
      symbol: 'RM',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'MY',
    ),
  ),
  ngn(
    'NGN',
    CurrencyFormatSpec(
      symbol: '₦',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'NG',
    ),
  ),
  nok(
    'NOK',
    CurrencyFormatSpec(
      symbol: 'kr ',
      isSymbolLeading: true,
      thousandsSeparator: '\u2009\u2009',
      decimalSeparator: ',',
      decimalPlaces: 2,
      currencyCountryCode: 'NO',
    ),
  ),
  nzd(
    'NZD',
    CurrencyFormatSpec(
      symbol: 'NZ\$ ',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'NZ',
    ),
  ),
  pln(
    'PLN',
    CurrencyFormatSpec(
      symbol: 'zł',
      isSymbolLeading: false,
      thousandsSeparator: '\u2009\u2009',
      decimalSeparator: ',',
      decimalPlaces: 2,
      currencyCountryCode: 'PL',
    ),
  ),
  rub(
    'RUB',
    CurrencyFormatSpec(
      symbol: '₽',
      isSymbolLeading: false,
      thousandsSeparator: '\u2009\u2009',
      decimalSeparator: ',',
      decimalPlaces: 2,
      currencyCountryCode: 'RU',
    ),
  ),
  sek(
    'SEK',
    CurrencyFormatSpec(
      symbol: 'kr',
      isSymbolLeading: false,
      thousandsSeparator: '\u2009\u2009',
      decimalSeparator: ',',
      decimalPlaces: 2,
      currencyCountryCode: 'SE',
    ),
  ),
  sgd(
    'SGD',
    CurrencyFormatSpec(
      symbol: 'S\$',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'SG',
    ),
  ),
  thb(
    'THB',
    CurrencyFormatSpec(
      symbol: '฿',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'TH',
    ),
  ),
  turkishLira(
    'TRY',
    CurrencyFormatSpec(
      symbol: '₺',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'TR',
    ),
  ),
  vnd(
    'VND',
    CurrencyFormatSpec(
      symbol: '₫',
      isSymbolLeading: true,
      thousandsSeparator: '.',
      decimalSeparator: ',',
      decimalPlaces: 2,
      currencyCountryCode: 'VN',
    ),
  ),
  zar(
    'ZAR',
    CurrencyFormatSpec(
      symbol: 'R',
      isSymbolLeading: true,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      decimalPlaces: 2,
      currencyCountryCode: 'ZA',
    ),
  );

  final String value;
  final CurrencyFormatSpec format;

  const FiatCurrency(this.value, this.format);

  String toStringWithSymbol() => '$value (${format.symbol})';

  bool get isUsd => value == 'USD';
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
  };

  return label;
}

enum ExchangeRateSource {
  bitfinex('BITFINEX', 'Bitfinex'),
  bitstamp('BITSTAMP', 'Bitstamp'),
  kraken('KRAKEN', 'Kraken'),
  coingecko('COINGECKO', 'Coingecko'),
  bullbitcoin('BULLBITCOIN', 'Bullbitcoin');

  const ExchangeRateSource(this.value, this.displayName);

  final String value;
  final String displayName;
}

@freezed
class ExchangeRate with _$ExchangeRate {
  const ExchangeRate._();

  const factory ExchangeRate(
    FiatCurrency currency,
    ExchangeRateSource source,
  ) = _ExchangeRate;

  String displayName(BuildContext context) {
    final label = currencyLabelLookup(currency, context);
    final signAndCode = currency.format.symbol != currency.value
        ? '(${currency.format.symbol} ${currency.value})'
        : '(${currency.format.symbol})';
    return '$label $signAndCode';
  }

  String shortName(BuildContext context) {
    final signAndCode = currency.format.symbol != currency.value
        ? currency.value
        : currency.format.symbol;
    return signAndCode;
  }

  String get svgPath => currency.format.flagSvg;
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

extension BitcoinFiatRatesResponseX on BitcoinFiatRatesResponse {
  bool get isUsd => code == 'USD';
}
