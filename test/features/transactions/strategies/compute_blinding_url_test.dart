import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';
import 'transaction_details_test_helper.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Asset.lbtc());
    registerFallbackValue(MockAppLocalizations());
  });

  group('computeBlindingUrl', () {
    late StrategyDetailsTestSetup setup;
    late ProviderContainer container;
    late TransactionUiModelCreator strategy;

    setUp(() {
      setup = StrategyDetailsTestSetup();
      setup.setUp();
      container = setup.createContainer();
      strategy = container.read(aquaTransactionUiModelsProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('returns empty string for null transaction', () {
      final result = strategy.computeBlindingUrl(null, Asset.lbtc());

      expect(result, isEmpty);
    });

    test('returns empty string for non-Liquid asset', () {
      final transaction = _createTransaction(
        txhash: 'btc_tx',
        inputs: [_createInOut(blinders: ('amt1', 'asset1'))],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.btc());

      expect(result, isEmpty);
    });

    test('returns empty string when no inputs or outputs have blinders', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        inputs: [_createInOut(blinders: null)],
        outputs: [_createInOut(blinders: null)],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      expect(result, isEmpty);
    });

    test('computes blinding URL with input blinders only', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        inputs: [
          _createInOut(
            satoshi: 100000000,
            assetId: 'asset_id_1',
            blinders: ('amount_blinder_1', 'asset_blinder_1'),
          ),
        ],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      expect(
          result,
          equals(
              'tx_hash#blinded=100000000,asset_id_1,amount_blinder_1,asset_blinder_1'));
    });

    test('computes blinding URL with output blinders only', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        outputs: [
          _createInOut(
            satoshi: 50000000,
            assetId: 'asset_id_2',
            blinders: ('amount_blinder_2', 'asset_blinder_2'),
          ),
        ],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      expect(
          result,
          equals(
              'tx_hash#blinded=50000000,asset_id_2,amount_blinder_2,asset_blinder_2'));
    });

    test('computes blinding URL with multiple inputs', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        inputs: [
          _createInOut(
            satoshi: 100000000,
            assetId: 'asset_1',
            blinders: ('amt_blind_1', 'asset_blind_1'),
          ),
          _createInOut(
            satoshi: 200000000,
            assetId: 'asset_2',
            blinders: ('amt_blind_2', 'asset_blind_2'),
          ),
        ],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      expect(
          result,
          equals(
              'tx_hash#blinded=100000000,asset_1,amt_blind_1,asset_blind_1,200000000,asset_2,amt_blind_2,asset_blind_2'));
    });

    test('computes blinding URL with multiple outputs', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        outputs: [
          _createInOut(
            satoshi: 50000000,
            assetId: 'asset_1',
            blinders: ('amt_blind_1', 'asset_blind_1'),
          ),
          _createInOut(
            satoshi: 30000000,
            assetId: 'asset_2',
            blinders: ('amt_blind_2', 'asset_blind_2'),
          ),
        ],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      expect(
          result,
          equals(
              'tx_hash#blinded=50000000,asset_1,amt_blind_1,asset_blind_1,30000000,asset_2,amt_blind_2,asset_blind_2'));
    });

    test('computes blinding URL with both inputs and outputs', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        inputs: [
          _createInOut(
            satoshi: 100000000,
            assetId: 'input_asset',
            blinders: ('in_amt', 'in_asset'),
          ),
        ],
        outputs: [
          _createInOut(
            satoshi: 90000000,
            assetId: 'output_asset',
            blinders: ('out_amt', 'out_asset'),
          ),
        ],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      expect(
          result,
          equals(
              'tx_hash#blinded=100000000,input_asset,in_amt,in_asset,90000000,output_asset,out_amt,out_asset'));
    });

    test('skips inputs without blinders', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        inputs: [
          _createInOut(
            satoshi: 100000000,
            assetId: 'asset_1',
            blinders: ('amt_1', 'asset_1_blind'),
          ),
          _createInOut(
            satoshi: 200000000,
            assetId: 'asset_2',
            blinders: null, // No blinders
          ),
          _createInOut(
            satoshi: 300000000,
            assetId: 'asset_3',
            blinders: ('amt_3', 'asset_3_blind'),
          ),
        ],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      // Should only include asset_1 and asset_3
      expect(
          result,
          equals(
              'tx_hash#blinded=100000000,asset_1,amt_1,asset_1_blind,300000000,asset_3,amt_3,asset_3_blind'));
    });

    test('skips outputs without blinders', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        outputs: [
          _createInOut(
            satoshi: 50000000,
            assetId: 'asset_1',
            blinders: ('amt_1', 'asset_1_blind'),
          ),
          _createInOut(
            satoshi: 30000000,
            assetId: 'asset_2',
            blinders: null, // No blinders
          ),
        ],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      // Should only include asset_1
      expect(result,
          equals('tx_hash#blinded=50000000,asset_1,amt_1,asset_1_blind'));
    });

    test('skips inputs with partial blinders (null amount)', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        inputs: [
          const GdkTransactionInOut(
            satoshi: 100000000,
            assetId: 'asset_1',
            amountBlinder: null, // Missing amount blinder
            assetBlinder: 'asset_blind',
          ),
        ],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      expect(result, isEmpty); // No complete blinders
    });

    test('skips inputs with partial blinders (null asset)', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        inputs: [
          const GdkTransactionInOut(
            satoshi: 100000000,
            assetId: 'asset_1',
            amountBlinder: 'amt_blind',
            assetBlinder: null, // Missing asset blinder
          ),
        ],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      expect(result, isEmpty); // No complete blinders
    });

    test('handles empty inputs and outputs lists', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        inputs: [],
        outputs: [],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      expect(result, isEmpty);
    });

    test('handles null inputs and outputs lists', () {
      const transaction = GdkTransaction(
        txhash: 'tx_hash',
        type: GdkTransactionTypeEnum.outgoing,
        satoshi: {},
        inputs: null,
        outputs: null,
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      expect(result, isEmpty);
    });

    test('works for USDt Liquid asset', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        inputs: [
          _createInOut(
            satoshi: 10000000,
            assetId: Asset.usdtLiquid().id,
            blinders: ('amt', 'asset'),
          ),
        ],
      );

      final result =
          strategy.computeBlindingUrl(transaction, Asset.usdtLiquid());

      expect(result, isNotEmpty);
      expect(result, contains('tx_hash#blinded='));
    });

    test('format matches expected URL structure', () {
      final transaction = _createTransaction(
        txhash: 'abc123',
        inputs: [
          _createInOut(
            satoshi: 100,
            assetId: 'asset_x',
            blinders: ('amt_blind', 'asset_blind'),
          ),
        ],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      // Verify format: {txhash}#blinded={data}
      expect(result, startsWith('abc123#blinded='));
      expect(result, contains(','));
      expect(result.split(','),
          hasLength(4)); // satoshi,assetId,amtBlinder,assetBlinder
    });

    test('preserves order: inputs first, then outputs', () {
      final transaction = _createTransaction(
        txhash: 'tx_hash',
        inputs: [
          _createInOut(
            satoshi: 1,
            assetId: 'in',
            blinders: ('in_amt', 'in_asset'),
          ),
        ],
        outputs: [
          _createInOut(
            satoshi: 2,
            assetId: 'out',
            blinders: ('out_amt', 'out_asset'),
          ),
        ],
      );

      final result = strategy.computeBlindingUrl(transaction, Asset.lbtc());

      // Input should come before output in the URL
      final parts = result.split('#blinded=')[1].split(',');
      expect(parts[0], equals('1')); // Input satoshi
      expect(parts[1], equals('in')); // Input asset
      expect(parts[4], equals('2')); // Output satoshi
      expect(parts[5], equals('out')); // Output asset
    });
  });
}

GdkTransaction _createTransaction({
  required String txhash,
  List<GdkTransactionInOut>? inputs,
  List<GdkTransactionInOut>? outputs,
}) {
  return GdkTransaction(
    txhash: txhash,
    type: GdkTransactionTypeEnum.outgoing,
    satoshi: {},
    inputs: inputs,
    outputs: outputs,
  );
}

GdkTransactionInOut _createInOut({
  int? satoshi,
  String? assetId,
  (String amountBlinder, String assetBlinder)? blinders,
}) {
  return GdkTransactionInOut(
    satoshi: satoshi,
    assetId: assetId,
    amountBlinder: blinders?.$1,
    assetBlinder: blinders?.$2,
  );
}
