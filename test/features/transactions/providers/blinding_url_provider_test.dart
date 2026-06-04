import 'package:aqua/data/data.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lwk/lwk.dart' show TxOutSecrets;

void main() {
  late BlindingUrlHelper helper;

  setUp(() {
    helper = BlindingUrlHelper();
  });

  group('gdkInOutsToBlindingStrings', () {
    test('formats single inout with all blinders', () {
      final inOuts = [
        const GdkTransactionInOut(
          satoshi: 100000,
          assetId: 'asset_1',
          amountBlinder: 'amt_bf_1',
          assetBlinder: 'asset_bf_1',
        ),
      ];

      final result = helper.gdkInOutsToBlindingStrings(inOuts).toList();

      expect(result, hasLength(1));
      expect(result[0], equals('100000,asset_1,amt_bf_1,asset_bf_1'));
    });

    test('formats multiple inouts', () {
      final inOuts = [
        const GdkTransactionInOut(
          satoshi: 100,
          assetId: 'a1',
          amountBlinder: 'ab1',
          assetBlinder: 'sb1',
        ),
        const GdkTransactionInOut(
          satoshi: 200,
          assetId: 'a2',
          amountBlinder: 'ab2',
          assetBlinder: 'sb2',
        ),
      ];

      final result = helper.gdkInOutsToBlindingStrings(inOuts).toList();

      expect(result, hasLength(2));
      expect(result[0], equals('100,a1,ab1,sb1'));
      expect(result[1], equals('200,a2,ab2,sb2'));
    });

    test('skips entries with null amountBlinder', () {
      final inOuts = [
        const GdkTransactionInOut(
          satoshi: 100,
          assetId: 'a1',
          amountBlinder: null,
          assetBlinder: 'sb1',
        ),
      ];

      expect(helper.gdkInOutsToBlindingStrings(inOuts), isEmpty);
    });

    test('skips entries with null assetBlinder', () {
      final inOuts = [
        const GdkTransactionInOut(
          satoshi: 100,
          assetId: 'a1',
          amountBlinder: 'ab1',
          assetBlinder: null,
        ),
      ];

      expect(helper.gdkInOutsToBlindingStrings(inOuts), isEmpty);
    });

    test('skips entries with both blinders null', () {
      final inOuts = [
        const GdkTransactionInOut(
          satoshi: 100,
          assetId: 'a1',
        ),
      ];

      expect(helper.gdkInOutsToBlindingStrings(inOuts), isEmpty);
    });

    test('uses 0 for null satoshi', () {
      final inOuts = [
        const GdkTransactionInOut(
          satoshi: null,
          assetId: 'a1',
          amountBlinder: 'ab1',
          assetBlinder: 'sb1',
        ),
      ];

      final result = helper.gdkInOutsToBlindingStrings(inOuts).toList();

      expect(result[0], startsWith('0,'));
    });

    test('returns empty iterable for empty list', () {
      expect(helper.gdkInOutsToBlindingStrings([]), isEmpty);
    });

    test('filters mixed entries keeping only those with complete blinders', () {
      final inOuts = [
        const GdkTransactionInOut(
          satoshi: 100,
          assetId: 'a1',
          amountBlinder: 'ab1',
          assetBlinder: 'sb1',
        ),
        const GdkTransactionInOut(
          satoshi: 200,
          assetId: 'a2',
          amountBlinder: null,
          assetBlinder: 'sb2',
        ),
        const GdkTransactionInOut(
          satoshi: 300,
          assetId: 'a3',
          amountBlinder: 'ab3',
          assetBlinder: 'sb3',
        ),
      ];

      final result = helper.gdkInOutsToBlindingStrings(inOuts).toList();

      expect(result, hasLength(2));
      expect(result[0], equals('100,a1,ab1,sb1'));
      expect(result[1], equals('300,a3,ab3,sb3'));
    });
  });

  group('txOutSecretsToBlindingData', () {
    test('formats single TxOutSecrets', () {
      final secrets = [
        TxOutSecrets(
          value: BigInt.from(50000),
          asset: 'asset_id',
          valueBf: 'value_bf_hex',
          assetBf: 'asset_bf_hex',
        ),
      ];

      final result = helper.txOutSecretsToBlindingData(secrets);

      expect(result, equals('50000,asset_id,value_bf_hex,asset_bf_hex'));
    });

    test('formats multiple TxOutSecrets joined by commas', () {
      final secrets = [
        TxOutSecrets(
          value: BigInt.from(100),
          asset: 'a1',
          valueBf: 'vb1',
          assetBf: 'ab1',
        ),
        TxOutSecrets(
          value: BigInt.from(200),
          asset: 'a2',
          valueBf: 'vb2',
          assetBf: 'ab2',
        ),
      ];

      final result = helper.txOutSecretsToBlindingData(secrets);

      expect(result, equals('100,a1,vb1,ab1,200,a2,vb2,ab2'));
    });

    test('returns empty string for empty list', () {
      expect(helper.txOutSecretsToBlindingData([]), isEmpty);
    });

    test('handles large BigInt values', () {
      final secrets = [
        TxOutSecrets(
          value: BigInt.parse('999999999999999'),
          asset: 'a',
          valueBf: 'v',
          assetBf: 's',
        ),
      ];

      final result = helper.txOutSecretsToBlindingData(secrets);

      expect(result, startsWith('999999999999999,'));
    });
  });

  group('buildBlindingUrl', () {
    test('returns empty string for non-Liquid asset', () {
      final result = helper.buildBlindingUrl(
        txhash: 'tx123',
        isLiquid: false,
        inputs: [
          const GdkTransactionInOut(
            satoshi: 100,
            assetId: 'a1',
            amountBlinder: 'ab',
            assetBlinder: 'sb',
          ),
        ],
      );

      expect(result, isEmpty);
    });

    test('returns empty string when no data sources have data', () {
      final result = helper.buildBlindingUrl(
        txhash: 'tx123',
        isLiquid: true,
      );

      expect(result, isEmpty);
    });

    test('returns empty string with empty lists and no stored data', () {
      final result = helper.buildBlindingUrl(
        txhash: 'tx123',
        isLiquid: true,
        inputs: [],
        outputs: [],
        storedBlindingData: null,
      );

      expect(result, isEmpty);
    });

    test('builds URL from GDK inputs only', () {
      final result = helper.buildBlindingUrl(
        txhash: 'tx123',
        isLiquid: true,
        inputs: [
          const GdkTransactionInOut(
            satoshi: 100,
            assetId: 'a1',
            amountBlinder: 'ab',
            assetBlinder: 'sb',
          ),
        ],
      );

      expect(result, equals('tx123#blinded=100,a1,ab,sb'));
    });

    test('builds URL from GDK outputs only', () {
      final result = helper.buildBlindingUrl(
        txhash: 'tx123',
        isLiquid: true,
        outputs: [
          const GdkTransactionInOut(
            satoshi: 200,
            assetId: 'a2',
            amountBlinder: 'ab2',
            assetBlinder: 'sb2',
          ),
        ],
      );

      expect(result, equals('tx123#blinded=200,a2,ab2,sb2'));
    });

    test('builds URL from stored blinding data only', () {
      final result = helper.buildBlindingUrl(
        txhash: 'tx123',
        isLiquid: true,
        storedBlindingData: '500,stored_asset,stored_vbf,stored_abf',
      );

      expect(result,
          equals('tx123#blinded=500,stored_asset,stored_vbf,stored_abf'));
    });

    test('combines GDK inputs/outputs with stored blinding data', () {
      final result = helper.buildBlindingUrl(
        txhash: 'tx123',
        isLiquid: true,
        inputs: [
          const GdkTransactionInOut(
            satoshi: 100,
            assetId: 'a1',
            amountBlinder: 'ab1',
            assetBlinder: 'sb1',
          ),
        ],
        outputs: [
          const GdkTransactionInOut(
            satoshi: 200,
            assetId: 'a2',
            amountBlinder: 'ab2',
            assetBlinder: 'sb2',
          ),
        ],
        storedBlindingData: '300,a3,vb3,ab3',
      );

      expect(
        result,
        equals('tx123#blinded=100,a1,ab1,sb1,200,a2,ab2,sb2,300,a3,vb3,ab3'),
      );
    });

    test('ignores empty stored blinding data string', () {
      final result = helper.buildBlindingUrl(
        txhash: 'tx123',
        isLiquid: true,
        inputs: [
          const GdkTransactionInOut(
            satoshi: 100,
            assetId: 'a1',
            amountBlinder: 'ab',
            assetBlinder: 'sb',
          ),
        ],
        storedBlindingData: '',
      );

      expect(result, equals('tx123#blinded=100,a1,ab,sb'));
    });

    test('ignores null stored blinding data', () {
      final result = helper.buildBlindingUrl(
        txhash: 'tx123',
        isLiquid: true,
        inputs: [
          const GdkTransactionInOut(
            satoshi: 100,
            assetId: 'a1',
            amountBlinder: 'ab',
            assetBlinder: 'sb',
          ),
        ],
        storedBlindingData: null,
      );

      expect(result, equals('tx123#blinded=100,a1,ab,sb'));
    });

    test('preserves order: inputs, outputs, then stored data', () {
      final result = helper.buildBlindingUrl(
        txhash: 'tx',
        isLiquid: true,
        inputs: [
          const GdkTransactionInOut(
            satoshi: 1,
            assetId: 'in',
            amountBlinder: 'in_ab',
            assetBlinder: 'in_sb',
          ),
        ],
        outputs: [
          const GdkTransactionInOut(
            satoshi: 2,
            assetId: 'out',
            amountBlinder: 'out_ab',
            assetBlinder: 'out_sb',
          ),
        ],
        storedBlindingData: '3,stored,s_ab,s_sb',
      );

      final blindedPart = result.split('#blinded=')[1];
      final quadruples = <String>[];
      final values = blindedPart.split(',');
      for (var i = 0; i < values.length; i += 4) {
        quadruples.add(values.sublist(i, i + 4).join(','));
      }

      expect(quadruples[0], equals('1,in,in_ab,in_sb'));
      expect(quadruples[1], equals('2,out,out_ab,out_sb'));
      expect(quadruples[2], equals('3,stored,s_ab,s_sb'));
    });

    test('returns stored data alone when GDK inputs have no complete blinders',
        () {
      final result = helper.buildBlindingUrl(
        txhash: 'tx123',
        isLiquid: true,
        inputs: [
          const GdkTransactionInOut(
            satoshi: 100,
            assetId: 'a1',
            amountBlinder: null,
            assetBlinder: 'sb',
          ),
        ],
        storedBlindingData: '500,payjoin_asset,pj_vbf,pj_abf',
      );

      expect(result, equals('tx123#blinded=500,payjoin_asset,pj_vbf,pj_abf'));
    });
  });
}
