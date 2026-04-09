import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';

import '../../../../mocks/mocks.dart';

List<Override> getStandardOverrides({
  MockAddressParserProvider? addressParser,
  MockManageAssetsProvider? manageAssets,
  MockBitcoinProvider? bitcoin,
  MockBalanceProvider? balance,
  MockUserPreferencesNotifier? prefs,
  Future<String?>? clipboardContent,
  MockDisplayUnitsProvider? mockDisplayUnitsProvider,
  ReferenceExchangeRateProviderMock? mockExchangeRatesProvider,
}) =>
    [
      clipboardContentProvider
          .overrideWith((_) => clipboardContent ?? Future.value(null)),
      addressParserProvider
          .overrideWith((_) => addressParser ?? MockAddressParserProvider()),
      manageAssetsProvider
          .overrideWith((_) => manageAssets ?? MockManageAssetsProvider()),
      bitcoinProvider.overrideWith((_) => bitcoin ?? MockBitcoinProvider()),
      balanceProvider.overrideWith((_) => balance ?? MockBalanceProvider()),
      prefsProvider.overrideWith((_) => prefs ?? MockUserPreferencesNotifier()),
      fiatRatesProvider.overrideWith(() => MockFiatRatesNotifier(rates: [
            const BitcoinFiatRatesResponse(
              name: 'US Dollar',
              cryptoCode: 'BTC',
              currencyPair: 'BTCUSD',
              code: 'USD',
              rate: 56690.0,
            ),
            const BitcoinFiatRatesResponse(
              name: 'Euro',
              cryptoCode: 'BTC',
              currencyPair: 'BTCEUR',
              code: 'EUR',
              rate: 28342.0,
            ),
          ])),
      formatterProvider.overrideWith((ref) => FormatterProvider(ref)),
      formatProvider.overrideWith((ref) => FormatService(ref)),
      displayUnitsProvider.overrideWith(
          (ref) => mockDisplayUnitsProvider ?? MockDisplayUnitsProvider()),
      exchangeRatesProvider.overrideWith((ref) =>
          mockExchangeRatesProvider ?? ReferenceExchangeRateProviderMock()),
      amountInputMutationsProvider
          .overrideWith((ref) => MockCryptoAmountInputMutationsNotifier()),
      amountInputServiceProvider.overrideWith((ref) => AmountInputService(
            formatterProvider: ref.read(formatterProvider),
            formatProvider: ref.read(formatProvider),
            fiatRatesProvider: ref.watch(fiatRatesProvider),
            unitsProvider: ref.read(displayUnitsProvider),
          )),
    ];
