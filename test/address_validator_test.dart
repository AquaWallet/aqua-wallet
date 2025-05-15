import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/address_validator/address_validator.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLiquidProvider extends Mock implements LiquidProvider {}

class MockBitcoinProvider extends Mock implements BitcoinProvider {}

class MockBalanceService extends Mock implements BalanceService {}

void main() {
  final mockLiquidProvider = MockLiquidProvider();
  final mockBitcoinProvider = MockBitcoinProvider();
  final mockBalanceService = MockBalanceService();

  setUp(() {
    when(() => mockBalanceService.getLBTCBalance())
        .thenAnswer((_) async => 10000);
  });

  group('Bitcoin and Liquid', () {
    setUp(() {
      when(() => mockLiquidProvider.isValidAddress(any()))
          .thenAnswer((_) async => true);
      when(() => mockBitcoinProvider.isValidAddress(any()))
          .thenAnswer((_) async => true);
    });

    final container = ProviderContainer(overrides: [
      liquidProvider.overrideWithValue(mockLiquidProvider),
      bitcoinProvider.overrideWithValue(mockBitcoinProvider),
      balanceProvider.overrideWithValue(mockBalanceService),
    ]);

    test('Bitcoin address', () async {
      const address = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';
      final asset = await container
          .read(addressParserProvider)
          .parseAsset(address: address);
      expect(asset, Asset.btc());
    });

    test('Liquid address', () async {
      const address =
          'VJLEjJNWQsD4x7cFBiuj54m7BpVhvxcff8nVjynvBECE5QefcSV5zjcaXjsN8LTKLsQhPmMzGT';
      final asset = await container
          .read(addressParserProvider)
          .parseAsset(address: address);
      expect(asset, isNotNull); // Replace with actual Liquid asset check
    });
  });

  group('BIP21', () {
    final container = ProviderContainer(overrides: [
      liquidProvider.overrideWithValue(mockLiquidProvider),
      bitcoinProvider.overrideWithValue(mockBitcoinProvider),
      balanceProvider.overrideWithValue(mockBalanceService),
    ]);
    test('returns parsed address for valid bitcoin BIP21 input', () async {
      const input =
          'bitcoin:1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2?amount=1.23&label=Example';
      final asset = Asset.btc();
      const accountForCompatibleAssets = true;

      final result = await container
          .read(addressParserProvider)
          .parseBIP21(input, asset, accountForCompatibleAssets);

      expect(result, isNotNull);
      expect(result!.address, equals('1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2'));
      expect(result.amount, equals(DecimalExt.fromDouble(1.23)));
      expect(result.asset, equals(asset));
      expect(result.label, equals('Example'));
    });

    test('returns parsed address and assetId for valid liquid BIP21 input',
        () async {
      const input =
          'liquidnetwork:VJLEjJNWQsD4x7cFBiuj54m7BpVhvxcff8nVjynvBECE5QefcSV5zjcaXjsN8LTKLsQhPmMzGT?amount=1.23&assetid=ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2&label=Example';
      final asset = Asset.unknown();
      const accountForCompatibleAssets = true;

      final result = await container
          .read(addressParserProvider)
          .parseBIP21(input, asset, accountForCompatibleAssets);

      expect(result, isNotNull);
      expect(
          result!.address,
          equals(
              'VJLEjJNWQsD4x7cFBiuj54m7BpVhvxcff8nVjynvBECE5QefcSV5zjcaXjsN8LTKLsQhPmMzGT'));
      expect(result.amount, equals(DecimalExt.fromDouble(1.23)));
      expect(
          result.assetId,
          equals(
              'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2'));
      expect(result.label, equals('Example'));
    });

    test('returns parsed lightning invoice for BIP21 with lightning invoice',
        () async {
      const input =
          'bitcoin:BC1QYLH3U67J673H6Y6ALV70M0PL2YZ53TZHVXGG7U?amount=0.00001&label=sbddesign%3A%20For%20lunch%20Tuesday&message=For%20lunch%20Tuesday&lightning=LNBC10U1P3PJ257PP5YZTKWJCZ5FTL5LAXKAV23ZMZEKAW37ZK6KMV80PK4XAEV5QHTZ7QDPDWD3XGER9WD5KWM36YPRX7U3QD36KUCMGYP282ETNV3SHJCQZPGXQYZ5VQSP5USYC4LK9CHSFP53KVCNVQ456GANH60D89REYKDNGSMTJ6YW3NHVQ9QYYSSQJCEWM5CJWZ4A6RFJX77C490YCED6PEMK0UPKXHY89CMM7SCT66K8GNEANWYKZGDRWRFJE69H9U5U0W57RRCSYSAS7GADWMZXC8C6T0SPJAZUP6';
      final asset = Asset.lightning();
      const accountForCompatibleAssets = true;

      final result = await container
          .read(addressParserProvider)
          .parseBIP21(input, asset, accountForCompatibleAssets);

      expect(result, isNotNull);
      expect(result!.asset, equals(asset));
      expect(
          result.lightningInvoice,
          equals(
              "LNBC10U1P3PJ257PP5YZTKWJCZ5FTL5LAXKAV23ZMZEKAW37ZK6KMV80PK4XAEV5QHTZ7QDPDWD3XGER9WD5KWM36YPRX7U3QD36KUCMGYP282ETNV3SHJCQZPGXQYZ5VQSP5USYC4LK9CHSFP53KVCNVQ456GANH60D89REYKDNGSMTJ6YW3NHVQ9QYYSSQJCEWM5CJWZ4A6RFJX77C490YCED6PEMK0UPKXHY89CMM7SCT66K8GNEANWYKZGDRWRFJE69H9U5U0W57RRCSYSAS7GADWMZXC8C6T0SPJAZUP6"));
    });

    test('returns null for invalid BIP21 input', () async {
      const input = 'invalid:1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2';
      final asset = Asset.btc();
      const accountForCompatibleAssets = true;

      final result = await container
          .read(addressParserProvider)
          .parseBIP21(input, asset, accountForCompatibleAssets);

      expect(result, isNull);
    });
  });

  group('Lightning', () {
    final container = ProviderContainer(overrides: [
      liquidProvider.overrideWithValue(mockLiquidProvider),
      bitcoinProvider.overrideWithValue(mockBitcoinProvider),
      balanceProvider.overrideWithValue(mockBalanceService),
    ]);
    test('expired invoice return true (test for expiration elsewhere)',
        () async {
      expect(
        await container.read(addressParserProvider).isValidAddressForAsset(
            address:
                'lnbc100u1pjm2062pp5pxe5trpma4yfz9sra4rr7ahngk40ve0q9qztwr2qp0v57shmp7cqdp8f35kw6r5de5kueeqv3jhqmmnd96zqvpwxqcrqvgcqzzsxqrrssrzjqw4t06fjwutwa9rt37l6uqumpku9x4j5neevtn9pz04x0zfapqs72rymu5qq6rqqqqqqqqqqqqqqqqqq9qsp5x74u3tjywc3qw3fpf6jppqx2fz3epvqcyygsltrw7d5wzlm6avaq9qyyssqwp43q356y878e4t20uza5fl9g5k9sg5klk62qfsdfra7nanqf5e4jhr5nxhzx4st9jtc5fzpp92wk9qdj8m8csy6rdnmzn7nkatexucp5qstxg',
            asset: Asset.lightning()),
        true,
      );
    });

    test('lightning address returns true', () async {
      expect(
        await container.read(addressParserProvider).isValidAddressForAsset(
            address: 'blink@blink.sv', asset: Asset.lightning()),
        true,
      );
    });

    test('lnurl pay returns true', () async {
      expect(
        await container.read(addressParserProvider).isValidAddressForAsset(
            address: 'lnurl1dp68gurn8ghj7cm0wfjjucn5vdkkzupwd',
            asset: Asset.lightning()),
        true,
      );
    });

    test('no amount invoice return false', () async {
      expect(
        await container.read(addressParserProvider).isValidAddressForAsset(
            address:
                'lnbc1pjm2062pp5pxe5trpma4yfz9sra4rr7ahngk40ve0q9qztwr2qp0v57shmp7cqdp8f35kw6r5de5kueeqv3jhqmmnd96zqvpwxqcrqvgcqzzsxqrrssrzjqw4t06fjwutwa9rt37l6uqumpku9x4j5neevtn9pz04x0zfapqs72rymu5qq6rqqqqqqqqqqqqqqqqqq9qsp5x74u3tjywc3qw3fpf6jppqx2fz3epvqcyygsltrw7d5wzlm6avaq9qyyssqwp43q356y878e4t20uza5fl9g5k9sg5klk62qfsdfra7nanqf5e4jhr5nxhzx4st9jtc5fzpp92wk9qdj8m8csy6rdnmzn7nkatexucp5qstxg',
            asset: Asset.lightning()),
        false, // no amount invoice
      );
    });

    test('normal email return false', () async {
      expect(
        await container.read(addressParserProvider).isValidAddressForAsset(
            address: 'support@aqua.com', asset: Asset.lightning()),
        false,
      );
    });

    test('malformed lnurl return false', () async {
      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address: 'lnurldp68gurn8ghj7cm0wfjjucn5vdkkzupwd',
              asset: Asset.lightning()),
          false);
    });
  }, skip: true);

  group('Alt-USDts', () {
    final container = ProviderContainer(overrides: [
      liquidProvider.overrideWithValue(mockLiquidProvider),
      bitcoinProvider.overrideWithValue(mockBitcoinProvider),
      balanceProvider.overrideWithValue(mockBalanceService),
    ]);

    when(() => mockLiquidProvider.isValidAddress(any()))
        .thenAnswer((_) async => false);
    when(() => mockBitcoinProvider.isValidAddress(any()))
        .thenAnswer((_) async => false);

    test('Ethereum address', () async {
      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
              asset: Asset.usdtEth()),
          true);
    }, skip: true);

    test('Tron address', () async {
      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address: 'TNPeeaaFB7K9cmo4uQpcU32zGK8G1NYqeL',
              asset: Asset.usdtTrx()),
          true);
    }, skip: true);

    test('TON address validation', () async {
      // Valid TON addresses
      // User-friendly format - bounceable (EQ prefix)
      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address: 'EQAWzEKcdnykvXfUNouqdS62tvrp32bCxuKS6eQrS6ISgcLo',
              asset: Asset.usdtTon()),
          true);

      // User-friendly format - non-bounceable (UQ prefix) with base64url chars
      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address: 'UQAEudOOdVjVHXobQErrO-DO6ubuyB4mUsv-NjVC0hl0qDmx',
              asset: Asset.usdtTon()),
          true);

      // User-friendly format - non-bounceable with base64 chars (+ and /)
      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address: 'UQAWzEKcdnykvXfUNouqdS62tvrp32bCxuKS6eQrS6ISgZ/+',
              asset: Asset.usdtTon()),
          true);

      // Raw format - masterchain (-1)
      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address:
                  '-1:fcb91a3a3816d0f7b8c2c76108b8a9bc5a6b7a55bd79f8ab101c52db29232260',
              asset: Asset.usdtTon()),
          true);

      // Raw format - basechain (0)
      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address:
                  '0:16cc429c767ca4bd77d4368baa752eb6b6fae9df66c2c6e292e9e42b4ba21281',
              asset: Asset.usdtTon()),
          true);

      // Invalid TON addresses
      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address:
                  'kQAWzEKcdnykvXfUNouqdS62tvrp32bCxuKS6eQrS6ISgcLo', // Invalid prefix (not EQ/UQ)
              asset: Asset.usdtTon()),
          false);

      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address: 'EQAWzEKcdnykvXfUNouqdS62tv', // Too short
              asset: Asset.usdtTon()),
          false);

      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address:
                  '1:16cc429c767ca4bd77d4368baa752eb6b6fae9df66c2c6e292e9e42b4ba21281', // Invalid workchain (not 0 or -1)
              asset: Asset.usdtTon()),
          false);

      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address:
                  '0:16cc429c767ca4bd77d4368baa752eb6b6fae9df66c2c6e292e9e42b4ba2128', // Invalid hex length (63 chars)
              asset: Asset.usdtTon()),
          false);

      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address:
                  'EQAWzEKcdnykvXfUNouqdS62tvrp32bCxuKS6eQrS6ISgcLo==', // Invalid base64 padding
              asset: Asset.usdtTon()),
          false);
    });

    test('check for all supported assets', () async {
      expect(
        await container.read(addressParserProvider).parseAsset(
              address: '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy',
            ),
        equals(Asset.btc()),
      );
      expect(
        await container.read(addressParserProvider).parseAsset(
              address: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
            ),
        equals(Asset.usdtEth()),
      );
      expect(
        await container.read(addressParserProvider).parseAsset(
              address: 'TNPeeaaFB7K9cmo4uQpcU32zGK8G1NYqeL',
            ),
        equals(Asset.usdtTrx()),
      );
      // TODO: Uncomment when activated
      // expect(
      //   await container.read(addressParserProvider).parseAsset(
      //         address: '0x55d398326f99059fF775485246999027B3197955',
      //       ),
      //   equals(Asset.usdtBep()),
      // );
      // expect(
      //   await container.read(addressParserProvider).parseAsset(
      //         address: 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB',
      //       ),
      //   equals(Asset.usdtSol()),
      // );
      // expect(
      //   await container.read(addressParserProvider).parseAsset(
      //         address: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
      //       ),
      //   equals(Asset.usdtPol()),
      // );
      // expect(
      //   await container.read(addressParserProvider).parseAsset(
      //         address: 'EQBynBO23ywHy_CgarY9NK9FTz0yDsG82PtcbSTQgGoXwiuA',
      //       ),
      //   equals(Asset.usdtTon()),
      // );
    }, skip: true);
  });
}
