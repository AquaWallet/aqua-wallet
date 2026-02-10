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
    registerFallbackValue(MockAppLocalizations());
    registerFallbackValue(const BitcoinFiatRatesResponse(
      name: 'USD',
      cryptoCode: 'BTC',
      currencyPair: 'BTC_USD',
      code: 'USD',
      rate: 100000.0,
    ));
  });

  group('AquaTransactionUiModelCreator - Details Methods', () {
    late StrategyDetailsTestSetup setup;
    late ProviderContainer container;
    late AquaTransactionUiModelCreator strategy;

    setUp(() {
      setup = StrategyDetailsTestSetup();
      setup.setUp();
      container = setup.createContainer();

      strategy = container.read(aquaTransactionUiModelsProvider);
    });

    tearDown(() {
      container.dispose();
    });

    group('createPendingDetails', () {
      test('creates pending outgoing details for aquaSend', () async {
        final dbTxn = createMockDbTransaction(
          txhash: 'pending_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.aquaSend,
          isGhost: true,
          ghostTxnAmount: -50000000,
          ghostTxnCreatedAt: DateTime.now(),
          feeAssetId: Asset.lbtc().id,
          receiveAddress: 'recipient_address',
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.transactionId, 'pending_send');
            expect(details.isPending, true);
            expect(details.isFailed, false);
            expect(details.deliverAsset.id, Asset.lbtc().id);
            expect(details.feeAsset.id, Asset.lbtc().id);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('returns null for non-aqua transaction types', () async {
        final dbTxn = createMockDbTransaction(
          type: TransactionDbModelType.sideswapPegIn,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNull);
      });

      test(
          'pending send details include fiat amounts when conversion is available',
          () async {
        // Recreate container with conversion provider that returns fiat values
        container.dispose();
        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) {
              final (_, satoshiAmount) = params;
              if (satoshiAmount.abs() == 50000000) {
                return SatoshiToFiatConversionModel(
                  currencySymbol: '\$',
                  decimal: Decimal.parse('1000.50'),
                  formatted: '1,000.50',
                  formattedWithCurrency: '\$1,000.50',
                );
              }
              if (satoshiAmount == 1000) {
                return SatoshiToFiatConversionModel(
                  currencySymbol: '\$',
                  decimal: Decimal.parse('0.50'),
                  formatted: '0.50',
                  formattedWithCurrency: '\$0.50',
                );
              }
              return null;
            }),
          ],
        );
        strategy = container.read(aquaTransactionUiModelsProvider);

        final dbTxn = createMockDbTransaction(
          txhash: 'pending_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.aquaSend,
          isGhost: true,
          ghostTxnAmount: -50000000,
          ghostTxnFee: 1000,
          ghostTxnCreatedAt: DateTime.now(),
          feeAssetId: Asset.lbtc().id,
          receiveAddress: 'recipient_address',
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            // Verify fiat amounts are populated
            expect(details.deliverAmountFiat, isNotEmpty);
            expect(details.feeAmountFiat, isNotEmpty);

            // Verify the actual fiat values
            expect(details.deliverAmountFiat, '\$1,000.50');
            expect(details.feeAmountFiat, '\$0.50');
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('pending send includes value at time when stored', () async {
        final dbTxn = createMockDbTransaction(
          txhash: 'pending_send_with_rate',
          assetId: Asset.btc().id,
          type: TransactionDbModelType.aquaSend,
          isGhost: true,
          ghostTxnAmount: 50000000, // 0.5 BTC
          ghostTxnFee: 1000,
          ghostTxnCreatedAt: DateTime.now(),
          feeAssetId: Asset.btc().id,
          receiveAddress: 'bc1qrecipient',
          exchangeRateAtExecution: 45000.50, // Rate at time of send
          currencyAtExecution: 'USD',
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [Asset.btc()],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.transactionId, 'pending_send_with_rate');
            expect(details.dbTransaction!.exchangeRateAtExecution, 45000.50);
            expect(details.dbTransaction!.currencyAtExecution, 'USD');

            // Verify fiatAmountAtExecutionDisplay is now populated
            expect(details.fiatAmountAtExecutionDisplay, isNotNull);
            expect(details.fiatAmountAtExecutionDisplay, contains('22500.25'));
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });
    });

    group('createConfirmedDetails', () {
      test('creates outgoing details with confirmation count', () async {
        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_send',
          type: GdkTransactionTypeEnum.outgoing,
          blockHeight: 100,
          satoshi: {Asset.lbtc().id: -50000000},
          fee: 1000,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_send',
          assetId: Asset.lbtc().id,
          feeAssetId: Asset.lbtc().id,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.transactionId, 'confirmed_send');
            expect(details.confirmations, '2 confirmations');
            expect(details.deliverAsset.id, Asset.lbtc().id);
            expect(details.feeAsset.id, Asset.lbtc().id);
            verify(() => setup.mockConfirmationService
                .getConfirmationCount(any(), 100)).called(1);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('returns null when network transaction is missing', () async {
        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [],
          networkTransaction: null,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNull);
      });

      test('confirmed send includes value at time when rate stored', () async {
        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_send_with_rate',
          type: GdkTransactionTypeEnum.outgoing,
          blockHeight: 100,
          satoshi: {Asset.btc().id: -100000000}, // -1 BTC (send)
          fee: 2000,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_send_with_rate',
          assetId: Asset.btc().id,
          feeAssetId: Asset.btc().id,
          type: TransactionDbModelType.aquaSend,
          receiveAddress: 'bc1qrecipient',
          exchangeRateAtExecution: 44500.00,
          currencyAtExecution: 'EUR',
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [Asset.btc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.transactionId, 'confirmed_send_with_rate');
            expect(details.isPending, false);

            // Verify fiatAmountAtExecutionDisplay is populated
            expect(details.fiatAmountAtExecutionDisplay, isNotNull);
            expect(details.fiatAmountAtExecutionDisplay, contains('44500.00'));
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });
    });

    group('Common Helper Methods', () {
      test('getFeeAsset returns correct asset', () {
        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc(), Asset.usdtLiquid()],
          dbTransaction: createMockDbTransaction(
            feeAssetId: Asset.usdtLiquid().id,
          ),
        );

        final feeAsset = strategy.getFeeAsset(args);

        expect(feeAsset.id, Asset.usdtLiquid().id);
      });
    });

    group('USDt Fee Formatting', () {
      test('pending send with USDt fee formats feeAmount as USD', () async {
        // Recreate container with fiatRatesProvider mock for BTC->USD conversion
        container.dispose();
        container = setup.createContainer(
          additionalOverrides: [
            fiatRatesProvider.overrideWith(() {
              return MockFiatRatesNotifier(rates: [
                const BitcoinFiatRatesResponse(
                  name: 'USD',
                  cryptoCode: 'BTC',
                  currencyPair: 'BTC_USD',
                  code: 'USD',
                  rate: 100000.0, // $100k per BTC for easy math
                ),
              ]);
            }),
          ],
        );
        strategy = container.read(aquaTransactionUiModelsProvider);

        final dbTxn = createMockDbTransaction(
          txhash: 'pending_send_usdt_fee',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.aquaSend,
          isGhost: true,
          ghostTxnAmount: -50000000,
          ghostTxnFee: 1000000, // 1000000 USDT sats = 0.01 USDT
          ghostTxnCreatedAt: DateTime.now(),
          feeAssetId: Asset.usdtLiquid().id,
          receiveAddress: 'recipient_address',
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc(), Asset.usdtLiquid()],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            // Verify feeAmount is formatted as USD, not L-BTC format
            expect(details.feeAmount, '0.01');
            expect(details.feeAsset.id, Asset.usdtLiquid().id);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('confirmed send with USDt fee formats feeAmount as USD', () async {
        // Recreate container with fiatRatesProvider mock for BTC->USD conversion
        container.dispose();
        container = setup.createContainer(
          additionalOverrides: [
            fiatRatesProvider.overrideWith(() {
              return MockFiatRatesNotifier(rates: [
                const BitcoinFiatRatesResponse(
                  name: 'USD',
                  cryptoCode: 'BTC',
                  currencyPair: 'BTC_USD',
                  code: 'USD',
                  rate: 100000.0, // $100k per BTC for easy math
                ),
              ]);
            }),
          ],
        );
        strategy = container.read(aquaTransactionUiModelsProvider);

        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_send_usdt_fee',
          type: GdkTransactionTypeEnum.outgoing,
          blockHeight: 100,
          satoshi: {Asset.lbtc().id: -50000000},
          fee: 90, // 90 L-BTC sats = 0.0000009 BTC * $100k = $0.09
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_send_usdt_fee',
          assetId: Asset.lbtc().id,
          feeAssetId: Asset.usdtLiquid().id,
          ghostTxnAmount: -45000000,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc(), Asset.usdtLiquid()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            // Verify feeAmount is formatted as USD, not L-BTC format
            expect(details.feeAmount,
                '0.05'); // 50000000 - 45000000 = 5000000 / satsPerBtc = 0.05 USDT
            expect(details.feeAsset.id, Asset.usdtLiquid().id);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('L-BTC fee still uses asset format (not USD)', () async {
        final dbTxn = createMockDbTransaction(
          txhash: 'pending_send_lbtc_fee',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.aquaSend,
          isGhost: true,
          ghostTxnAmount: -50000000,
          ghostTxnFee: 1000,
          ghostTxnCreatedAt: DateTime.now(),
          feeAssetId: Asset.lbtc().id,
          receiveAddress: 'recipient_address',
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            // Verify L-BTC fee still uses asset format (not USD)
            expect(details.feeAmount, '0.00001'); // 1000 / 100000000
            expect(details.feeAsset.id, Asset.lbtc().id);
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
