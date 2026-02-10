import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';
import 'transaction_details_test_helper.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Asset.btc());
    registerFallbackValue(Asset.lbtc());
    registerFallbackValue(Asset.usdtLiquid());
    registerFallbackValue(MockAppLocalizations());
  });

  group('Fiat Conversion in Transaction Strategies', () {
    late StrategyDetailsTestSetup setup;
    late ProviderContainer container;

    setUp(() {
      setup = StrategyDetailsTestSetup();
      setup.setUp();
    });

    tearDown(() {
      container.dispose();
    });

    group('convertToFiat method', () {
      test('returns formatted fiat string when conversion is available',
          () async {
        final mockConversion = SatoshiToFiatConversionModel(
          currencySymbol: '\$',
          decimal: Decimal.parse('1234.56'),
          formatted: '1,234.56',
          formattedWithCurrency: '\$1,234.56',
        );

        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) => mockConversion),
          ],
        );

        final strategy = container.read(aquaTransactionUiModelsProvider);
        final result = strategy.convertToFiat(Asset.btc(), 100000000);

        expect(result, equals('\$1,234.56'));
      });

      test('returns empty string when conversion is null', () async {
        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) => null),
          ],
        );

        final strategy = container.read(aquaTransactionUiModelsProvider);
        final result = strategy.convertToFiat(Asset.btc(), 100000000);

        expect(result, isEmpty);
      });

      test('handles zero amount conversion', () async {
        final mockConversion = SatoshiToFiatConversionModel(
          currencySymbol: '\$',
          decimal: Decimal.zero,
          formatted: '0.00',
          formattedWithCurrency: '\$0.00',
        );

        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) => mockConversion),
          ],
        );

        final strategy = container.read(aquaTransactionUiModelsProvider);
        final result = strategy.convertToFiat(Asset.btc(), 0);

        expect(result, equals('\$0.00'));
      });

      test('handles negative amounts for send transactions', () async {
        final mockConversion = SatoshiToFiatConversionModel(
          currencySymbol: '\$',
          decimal: Decimal.parse('-500.00'),
          formatted: '-500.00',
          formattedWithCurrency: '-\$500.00',
        );

        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) => mockConversion),
          ],
        );

        final strategy = container.read(aquaTransactionUiModelsProvider);
        final result = strategy.convertToFiat(Asset.btc(), -50000000);

        expect(result, equals('-\$500.00'));
      });

      test('works with different currencies', () async {
        final mockConversion = SatoshiToFiatConversionModel(
          currencySymbol: '€',
          decimal: Decimal.parse('920.50'),
          formatted: '920.50',
          formattedWithCurrency: '€920.50',
        );

        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) => mockConversion),
          ],
        );

        final strategy = container.read(aquaTransactionUiModelsProvider);
        final result = strategy.convertToFiat(Asset.btc(), 100000000);

        expect(result, equals('€920.50'));
      });

      test('works for all strategy types', () async {
        final mockConversion = SatoshiToFiatConversionModel(
          currencySymbol: '\$',
          decimal: Decimal.parse('100.00'),
          formatted: '100.00',
          formattedWithCurrency: '\$100.00',
        );

        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) => mockConversion),
          ],
        );

        // Test all strategy types have convertToFiat
        final aquaStrategy = container.read(aquaTransactionUiModelsProvider);
        final pegStrategy = container.read(pegTransactionUiModelsProvider);
        final sideswapStrategy =
            container.read(sideswapSwapTransactionUiModelsProvider);
        final altUsdtStrategy =
            container.read(altUsdtTransactionUiModelsProvider);
        final lightningStrategy =
            container.read(lightningTransactionUiModelsProvider);

        expect(aquaStrategy.convertToFiat(Asset.btc(), 10000000),
            equals('\$100.00'));
        expect(pegStrategy.convertToFiat(Asset.btc(), 10000000),
            equals('\$100.00'));
        expect(sideswapStrategy.convertToFiat(Asset.lbtc(), 10000000),
            equals('\$100.00'));
        expect(altUsdtStrategy.convertToFiat(Asset.usdtLiquid(), 10000000),
            equals('\$100.00'));
        expect(lightningStrategy.convertToFiat(Asset.lbtc(), 10000000),
            equals('\$100.00'));
      });
    });

    group('Fiat conversion in details methods', () {
      test('aqua send details include fiat amounts', () async {
        final mockConversion = SatoshiToFiatConversionModel(
          currencySymbol: '\$',
          decimal: Decimal.parse('500.00'),
          formatted: '500.00',
          formattedWithCurrency: '\$500.00',
        );

        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) => mockConversion),
          ],
        );

        final strategy = container.read(aquaTransactionUiModelsProvider);

        final networkTxn = createMockNetworkTransaction(
          txhash: 'send_tx',
          type: GdkTransactionTypeEnum.outgoing,
          satoshi: {Asset.btc().id: -100000000},
          fee: 1000,
          blockHeight: 800000,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [Asset.btc()],
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.deliverAmountFiat, isNotEmpty);
            expect(details.feeAmountFiat, isNotEmpty);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('swap details include fiat amounts', () async {
        final mockConversion = SatoshiToFiatConversionModel(
          currencySymbol: '\$',
          decimal: Decimal.parse('100.00'),
          formatted: '100.00',
          formattedWithCurrency: '\$100.00',
        );

        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) => mockConversion),
          ],
        );

        final strategy =
            container.read(sideswapSwapTransactionUiModelsProvider);

        when(() => setup.mockAssetResolutionService.resolveSwapAssetsFromDb(
              dbTxn: any(named: 'dbTxn'),
              asset: any(named: 'asset'),
              availableAssets: any(named: 'availableAssets'),
              networkTxn: any(named: 'networkTxn'),
            )).thenReturn((
          fromAsset: Asset.lbtc(),
          toAsset: Asset.usdtLiquid(),
        ));

        final dbTxn = createMockDbTransaction(
          txhash: 'swap_tx',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.sideswapSwap,
          isGhost: true,
          ghostTxnAmount: -50000000,
          ghostTxnCreatedAt: DateTime.now(),
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc(), Asset.usdtLiquid()],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be swap'),
          receive: (_) => fail('Should be swap'),
          swap: (details) {
            expect(details.feeAmountFiat, isNotEmpty);
          },
          peg: (_) => fail('Should be swap'),
          redeposit: (_) => fail('Should be swap'),
        );
      });

      test('fiat conversion handles provider returning null gracefully',
          () async {
        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) => null),
          ],
        );

        final strategy = container.read(aquaTransactionUiModelsProvider);

        final networkTxn = createMockNetworkTransaction(
          txhash: 'send_tx',
          type: GdkTransactionTypeEnum.outgoing,
          satoshi: {Asset.btc().id: -100000000},
          fee: 1000,
          blockHeight: 800000,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [Asset.btc()],
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            // Should have empty strings, not crash
            expect(details.deliverAmountFiat, isEmpty);
            expect(details.feeAmountFiat, isEmpty);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });
    });
  });
}
