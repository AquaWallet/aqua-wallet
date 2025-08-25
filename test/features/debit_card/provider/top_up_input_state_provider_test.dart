import 'package:aqua/data/data.dart';
import 'package:aqua/features/feature_flags/providers/feature_switches_provider.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';

//TODO - Move all test constants in one place
const kPointOneBtc = 0.1;
const kPointOneBtcInSats = 10000000;
const kOneBtc = 1;
const kOneBtcInSats = 100000000;
const kBtcUsdRate = 56690;
const kOneHundredUsdInBtcSats = 176397;
const kOneHundredUsdInBtc = 0.00176397;
const kFakeLanguageCode = 'en_US';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockManageAssetsProvider = MockManageAssetsProvider();
  final mockAnkaraSwitchesProvider = MockAnkaraSwitchesNotifier();
  final mockBitcoinProvider = MockBitcoinProvider();
  final mockBalanceProvider = MockBalanceProvider();
  final mockTopUpAmountInputMutationsProvider =
      MockTopUpAmountInputMutationsProvider();
  final btcAsset = Asset.btc(amount: kOneHundredUsdInBtcSats);
  final mockAssetsProvider = MockAssetsNotifier(assets: [btcAsset]);
  final container = ProviderContainer(overrides: [
    assetsProvider.overrideWith(() => mockAssetsProvider),
    manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
    bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
    balanceProvider.overrideWith((_) => mockBalanceProvider),
    ankaraSwitchesProvider.overrideWith(() => mockAnkaraSwitchesProvider),
    topUpAmountInputMutationsProvider
        .overrideWith((_) => mockTopUpAmountInputMutationsProvider),
  ]);
  container.read(ankaraSwitchesProvider);
  setUpAll(() {
    registerFallbackValue(btcAsset);

    // Setup topUpAmountInputMutationsProvider mock
    when(() => mockTopUpAmountInputMutationsProvider.getConvertedAmountSats(
          text: any(named: 'text'),
          asset: any(named: 'asset'),
          isFiatInput: any(named: 'isFiatInput'),
        )).thenAnswer((invocation) async {
      final text = invocation.namedArguments[const Symbol('text')] as String;
      final isFiatInput =
          invocation.namedArguments[const Symbol('isFiatInput')] as bool;

      if (isFiatInput) {
        // Fiat to Sats conversion
        if (text == '100') {
          return kOneHundredUsdInBtcSats;
        } else if (text == '0') {
          return 0;
        }
        return kOneHundredUsdInBtcSats;
      } else {
        // Crypto to Sats conversion
        if (text == kPointOneBtc.toString()) {
          return kPointOneBtcInSats;
        } else if (text == '100') {
          return satsPerBtc * 100;
        } else if (text == '0' || text.isEmpty) {
          return 0;
        } else if (text == kOneHundredUsdInBtc.toString()) {
          return kOneHundredUsdInBtcSats;
        }
        return kOneHundredUsdInBtcSats;
      }
    });

    when(() => mockTopUpAmountInputMutationsProvider.getConvertedAmount(
          amountSats: any(named: 'amountSats'),
          asset: any(named: 'asset'),
          isFiatAmountInput: any(named: 'isFiatAmountInput'),
          withSymbol: any(named: 'withSymbol'),
        )).thenAnswer((invocation) async {
      final amountSats =
          invocation.namedArguments[const Symbol('amountSats')] as int;
      final isFiatAmountInput =
          invocation.namedArguments[const Symbol('isFiatAmountInput')] as bool;

      if (amountSats == 0) {
        return null;
      }

      if (isFiatAmountInput) {
        return '100.00';
      } else {
        return '100.00';
      }
    });
  });

  group('Initial State', () {
    test('Initial state balance is correct', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final state = await container.read(topUpInputStateProvider.future);

      expect(state.balanceInSats, kOneBtcInSats);
    });
    test('Initial state amount text field is empty', () async {
      final state = await container.read(topUpInputStateProvider.future);

      expect(state.amountFieldText, isNull);
      expect(state.isAmountFieldEmpty, true);
    });
    test('Initial state amount is zero', () async {
      final state = await container.read(topUpInputStateProvider.future);

      expect(state.amount, 0);
    });
    test('Initial state fiat amount is empty', () async {
      final state = await container.read(topUpInputStateProvider.future);

      expect(state.amountInUsd, null);
    });
    test('Initial state amount input is fiat', () async {
      final state = await container.read(topUpInputStateProvider.future);

      expect(state.amountInputType, CryptoAmountInputType.fiat);
      expect(state.isFiatAmountInput, true);
    });
  });

  group('BTC Amount', () {
    final asset = Asset.btc(amount: kOneHundredUsdInBtcSats);
    final mockAssetsProvider = MockAssetsNotifier(assets: [asset]);
    final mockAnkaraSwitchesProvider = MockAnkaraSwitchesNotifier();
    final mockPrefsProvider = MockPrefsProvider();
    final mockBalanceProvider = MockBalanceProvider();
    final mockBitcoinProvider = MockBitcoinProvider();
    final mockTopUpAmountInputMutationsProvider =
        MockTopUpAmountInputMutationsProvider();
    final container = ProviderContainer(overrides: [
      assetsProvider.overrideWith(() => mockAssetsProvider),
      manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
      bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
      balanceProvider.overrideWith((_) => mockBalanceProvider),
      prefsProvider.overrideWith((_) => mockPrefsProvider),
      ankaraSwitchesProvider.overrideWith(() => mockAnkaraSwitchesProvider),
      topUpAmountInputMutationsProvider
          .overrideWith((_) => mockTopUpAmountInputMutationsProvider),
    ]);
    mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
    container.read(ankaraSwitchesProvider);

    setUp(() {
      // Setup topUpAmountInputMutationsProvider mock for this group
      when(() => mockTopUpAmountInputMutationsProvider.getConvertedAmountSats(
            text: any(named: 'text'),
            asset: any(named: 'asset'),
            isFiatInput: any(named: 'isFiatInput'),
          )).thenAnswer((invocation) async {
        final text = invocation.namedArguments[const Symbol('text')] as String;
        final isFiatInput =
            invocation.namedArguments[const Symbol('isFiatInput')] as bool;

        if (isFiatInput) {
          // Fiat to Sats conversion
          if (text == '100') {
            return kOneHundredUsdInBtcSats;
          } else if (text == '0') {
            return 0;
          }
          return kOneHundredUsdInBtcSats;
        } else {
          // Crypto to Sats conversion
          if (text == kPointOneBtc.toString()) {
            return kPointOneBtcInSats;
          } else if (text == '100') {
            return satsPerBtc * 100;
          } else if (text == '0' || text.isEmpty) {
            return 0;
          } else if (text == kOneHundredUsdInBtc.toString()) {
            return kOneHundredUsdInBtcSats;
          }
          return kOneHundredUsdInBtcSats;
        }
      });

      when(() => mockTopUpAmountInputMutationsProvider.getConvertedAmount(
            amountSats: any(named: 'amountSats'),
            asset: any(named: 'asset'),
            isFiatAmountInput: any(named: 'isFiatAmountInput'),
            withSymbol: any(named: 'withSymbol'),
          )).thenAnswer((invocation) async {
        final amountSats =
            invocation.namedArguments[const Symbol('amountSats')] as int;
        final isFiatAmountInput = invocation
            .namedArguments[const Symbol('isFiatAmountInput')] as bool;

        if (amountSats == 0) {
          return null;
        }

        if (isFiatAmountInput) {
          return '100.00';
        } else {
          return '100.00';
        }
      });
    });

    test(
      'When crypto amount is entered, underlying amount should be correct',
      () async {
        mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
        mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

        final initialState =
            await container.read(topUpInputStateProvider.future);

        container
            .read(topUpInputStateProvider.notifier)
            .setInputType(CryptoAmountInputType.crypto);
        await container
            .read(topUpInputStateProvider.notifier)
            .setAmount(kPointOneBtc.toString());

        final state = await container.read(topUpInputStateProvider.future);
        expect(initialState.amount, 0);
        expect(state.amountFieldText, kPointOneBtc.toString());
        expect(state.amount, kPointOneBtcInSats);
      },
    );
    test(
      'When fiat amount is entered, underlying amount should be correct',
      () async {
        final initialState =
            await container.read(topUpInputStateProvider.future);

        container
            .read(topUpInputStateProvider.notifier)
            .setInputType(CryptoAmountInputType.fiat);
        await container.read(topUpInputStateProvider.notifier).setAmount('100');

        // Based on the mocked rate: 100 USD = 0.0017639795 BTC
        final state = await container.read(topUpInputStateProvider.future);
        expect(initialState.amount, 0);
        expect(state.amount, kOneHundredUsdInBtcSats);
        expect(state.amountFieldText, '100');
        expect(state.amountInUsd, '100');
      },
    );
    test('When input type changed, amount should reset', () async {
      await container.read(topUpInputStateProvider.future);

      container
          .read(topUpInputStateProvider.notifier)
          .setInputType(CryptoAmountInputType.crypto);
      await container
          .read(topUpInputStateProvider.notifier)
          .setAmount(kPointOneBtc.toString());
      final initialState = await container.read(topUpInputStateProvider.future);

      container
          .read(topUpInputStateProvider.notifier)
          .setInputType(CryptoAmountInputType.fiat);

      final state = await container.read(topUpInputStateProvider.future);
      expect(initialState.amount, kPointOneBtcInSats);
      expect(initialState.amountFieldText, kPointOneBtc.toString());
      expect(initialState.amountInputType, CryptoAmountInputType.crypto);
      expect(state.amount, 0);
      expect(state.amountFieldText, null);
      expect(state.amountInputType, CryptoAmountInputType.fiat);
    });
    test('When amount is zero, fiat amount is zero string', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final initialState = await container.read(topUpInputStateProvider.future);

      await container.read(topUpInputStateProvider.notifier).setAmount('0');

      final state = await container.read(topUpInputStateProvider.future);

      expect(initialState.amount, 0);
      expect(initialState.amountInUsd, null);
      expect(state.amount, 0);
      expect(state.amountInUsd, '0');
    });
    test('When non-zero crypto amount, fiat amount is NOT null', () async {
      final initialState = await container.read(topUpInputStateProvider.future);

      container
          .read(topUpInputStateProvider.notifier)
          .setInputType(CryptoAmountInputType.crypto);

      await container
          .read(topUpInputStateProvider.notifier)
          .setAmount(kOneHundredUsdInBtc.toString());

      final state = await container.read(topUpInputStateProvider.future);

      expect(initialState.amount, 0);
      expect(initialState.amountInUsd, null);
      expect(state.amount, kOneHundredUsdInBtcSats);
      expect(state.amountInUsd, '100.00');
    });
    test('When non-zero fiat amount, USD amount is NOT null', () async {
      final initialState = await container.read(topUpInputStateProvider.future);
      container
          .read(topUpInputStateProvider.notifier)
          .setInputType(CryptoAmountInputType.fiat);
      await container.read(topUpInputStateProvider.notifier).setAmount('100');

      final state = await container.read(topUpInputStateProvider.future);

      expect(initialState.amount, 0);
      expect(initialState.amountInUsd, null);
      expect(state.amount, kOneHundredUsdInBtcSats);
      expect(state.amountInUsd, '100');
    });
  });

  group('USDt Amount', () {
    final usdtAsset = Asset.usdtLiquid(amount: kOneHundredUsdInBtcSats);
    final mockAssetsProvider =
        MockAssetsNotifier(assets: [usdtAsset, btcAsset]);
    final mockAnkaraSwitchesProvider = MockAnkaraSwitchesNotifier();
    final mockBalanceProvider = MockBalanceProvider();
    final mockBitcoinProvider = MockBitcoinProvider();
    final mockTopUpAmountInputMutationsProvider =
        MockTopUpAmountInputMutationsProvider();
    final container = ProviderContainer(overrides: [
      assetsProvider.overrideWith(() => mockAssetsProvider),
      manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
      bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
      balanceProvider.overrideWith((_) => mockBalanceProvider),
      ankaraSwitchesProvider.overrideWith(() => mockAnkaraSwitchesProvider),
      topUpAmountInputMutationsProvider
          .overrideWith((_) => mockTopUpAmountInputMutationsProvider),
    ]);
    container.read(ankaraSwitchesProvider);

    setUp(() {
      // Setup topUpAmountInputMutationsProvider mock for this group
      when(() => mockTopUpAmountInputMutationsProvider.getConvertedAmountSats(
            text: any(named: 'text'),
            asset: any(named: 'asset'),
            isFiatInput: any(named: 'isFiatInput'),
          )).thenAnswer((invocation) async {
        final text = invocation.namedArguments[const Symbol('text')] as String;
        final isFiatInput =
            invocation.namedArguments[const Symbol('isFiatInput')] as bool;

        if (isFiatInput) {
          // Fiat to Sats conversion
          if (text == '100') {
            return kOneHundredUsdInBtcSats;
          } else if (text == '0') {
            return 0;
          }
          return kOneHundredUsdInBtcSats;
        } else {
          // Crypto to Sats conversion
          if (text == kPointOneBtc.toString()) {
            return kPointOneBtcInSats;
          } else if (text == '100') {
            return satsPerBtc * 100;
          } else if (text == '0' || text.isEmpty) {
            return 0;
          } else if (text == kOneHundredUsdInBtc.toString()) {
            return kOneHundredUsdInBtcSats;
          }
          return kOneHundredUsdInBtcSats;
        }
      });

      when(() => mockTopUpAmountInputMutationsProvider.getConvertedAmount(
            amountSats: any(named: 'amountSats'),
            asset: any(named: 'asset'),
            isFiatAmountInput: any(named: 'isFiatAmountInput'),
            withSymbol: any(named: 'withSymbol'),
          )).thenAnswer((invocation) async {
        final amountSats =
            invocation.namedArguments[const Symbol('amountSats')] as int;
        final isFiatAmountInput = invocation
            .namedArguments[const Symbol('isFiatAmountInput')] as bool;

        if (amountSats == 0) {
          return null;
        }

        if (isFiatAmountInput) {
          return '100.00';
        } else {
          return '100.00';
        }
      });
    });

    test(
      'When amount is entered, underlying amount should be correct',
      () async {
        mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
        mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
        final initialState =
            await container.read(topUpInputStateProvider.future);

        await container
            .read(topUpInputStateProvider.notifier)
            .selectAsset(usdtAsset);

        container
            .read(topUpInputStateProvider.notifier)
            .setInputType(CryptoAmountInputType.crypto);

        await container.read(topUpInputStateProvider.notifier).setAmount('100');

        final state = await container.read(topUpInputStateProvider.future);
        expect(initialState.amount, 0);
        expect(state.amount, satsPerBtc * 100);
        expect(state.amountFieldText, '100');
        expect(state.amountInUsd, '100');
      },
    );
    test('When non-zero amount, USD amount is NOT null', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final initialState = await container.read(topUpInputStateProvider.future);

      await container
          .read(topUpInputStateProvider.notifier)
          .selectAsset(usdtAsset);

      container
          .read(topUpInputStateProvider.notifier)
          .setInputType(CryptoAmountInputType.crypto);

      await container.read(topUpInputStateProvider.notifier).setAmount('100');

      final state = await container.read(topUpInputStateProvider.future);

      expect(initialState.amount, 0);
      expect(initialState.amountInUsd, null);
      expect(state.amount, satsPerBtc * 100);
      expect(state.amountInUsd, '100');
    });
  });
}
