import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:mocktail/mocktail.dart';

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

ProviderContainer createSendContainer({
  required SendAssetArguments args,
  required SendAssetInputState input,
  required MockSendGdkTransactor transactor,
  required MockFeatureFlagsProvider featureFlags,
  MockBoltzSubmarineSwapNotifier? boltzNotifier,
}) {
  final mockBitcoinProvider = MockBitcoinProvider();
  final mockLiquidProvider = MockLiquidProvider();
  final mockExchangeRatesProvider = ReferenceExchangeRateProviderMock();

  mockExchangeRatesProvider.mockGetCurrentCurrency(
    value: kBtcUsdExchangeRate,
  );
  when(() => mockBitcoinProvider.convertAmount(any()))
      .thenAnswer((_) async => const GdkAmountData(fiatRate: '1.0'));
  when(() => mockLiquidProvider.blindTransaction(any()))
      .thenAnswer((_) async => const GdkNewTransactionReply());

  return ProviderContainer(overrides: [
    sendAssetInputStateProvider.overrideWith(
      () => MockSendAssetInputStateNotifier(input: input),
    ),
    sendTransactionExecutorProvider(args).overrideWith((_) => transactor),
    featureFlagsProvider.overrideWith((_) => featureFlags),
    transactionStorageProvider
        .overrideWith(() => MockTransactionStorageProvider()),
    bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
    liquidProvider.overrideWith((_) => mockLiquidProvider),
    exchangeRatesProvider.overrideWith((_) => mockExchangeRatesProvider),
    if (boltzNotifier != null)
      boltzSubmarineSwapProvider.overrideWith((_) => boltzNotifier),
    if (boltzNotifier != null)
      boltzStorageProvider.overrideWith(() => MockBoltzStorageProvider()),
  ]);
}
