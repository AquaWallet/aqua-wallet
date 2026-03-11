import 'package:aqua/features/settings/settings.dart';

const kFakeContent = 'test content';
const kFakeBitcoinAddress = 'fake-bitcoin-address';
const kFakeEthereumAddress = 'fake-ethereum-address';
const kFakeLiquidAddress = 'fake-liquid-address';
const kFakeLiquidUsdtAddress = 'fake-liquid-usdt-address';
const kFakeLightningInvoice = 'fake-lightning-invoice';
const kFakeLanguageCode = 'en';

const kBtcUsdRate = 56690.0;
const kBtcUsdRateStr = '\$56,690.00';
const kBtcUsdRateSats = kBtcUsdRate / kOneBtcInSats;
const kOneHundredUsdInBtcSats = 176397;
const kOneHundredUsdInBtc = 0.00176397;
const kUsdCurrency = 'USD';
const kBtcUsdExchangeRate = ExchangeRate(
  FiatCurrency.usd,
  ExchangeRateSource.coingecko,
);
final kBtcUsdFiatRate = BitcoinFiatRatesResponse(
  rate: kBtcUsdRate,
  code: kBtcUsdExchangeRate.currency.value,
  name: kBtcUsdExchangeRate.currency.name,
  cryptoCode: kBtcUsdExchangeRate.currency.value,
  currencyPair: 'BTCUSD',
);

const kBtcEurRate = 28345.0;
const kBtcEurRateStr = '€28,345.00';
const kBtcEurRateSats = kBtcEurRate / kOneBtcInSats;
const kOneHundredEurInBtcSats = 352795; // 100 EUR in sats at rate 28,345
const kOneHundredEurInBtc = 0.00352795;
const kOneHundredEurInBtcDisplay = '0.00${kBtcSeparator}352${kBtcSeparator}795';
const kEurCurrency = 'EUR';
const kBtcEurExchangeRate = ExchangeRate(
  FiatCurrency.eur,
  ExchangeRateSource.bitfinex,
);
final kBtcEurFiatRate = BitcoinFiatRatesResponse(
  rate: kBtcEurRate,
  code: kBtcEurExchangeRate.currency.value,
  name: kBtcEurExchangeRate.currency.name,
  cryptoCode: kBtcEurExchangeRate.currency.value,
  currencyPair: 'BTCEUR',
);

const kPointOneBtc = 0.1;
const kPointOneBtcInSats = 10000000;
const kOneBtc = 1;
const kOneBtcInSats = 100000000;

const kOneBtcDisplay = '1.00${kBtcSeparator}000${kBtcSeparator}000';
const kOneHundredUsdInBtcDisplay = '0.00${kBtcSeparator}176${kBtcSeparator}397';

const kOneHundredUsdtInSats = 10000000000;

const kOneThousandUsdInBtcSats = 1763979;
const kOneThousandUsdInBtcDisplay =
    '0.01${kBtcSeparator}763${kBtcSeparator}979';

const kBtcSeparator = ' ';
