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

  // we call gdk for `isValidAddress` for liquid and bitcoin, so no need to test
  when(() => mockLiquidProvider.isValidAddress(any()))
      .thenAnswer((_) async => true);
  when(() => mockBitcoinProvider.isValidAddress(any()))
      .thenAnswer((_) async => true);

  when(() => mockBalanceService.getLBTCBalance())
      .thenAnswer((_) async => 10000);

  final container = ProviderContainer(overrides: [
    liquidProvider.overrideWithValue(mockLiquidProvider),
    bitcoinProvider.overrideWithValue(mockBitcoinProvider),
    balanceProvider.overrideWithValue(mockBalanceService),
  ]);

  group('Bitcoin', () {
    test('invalid addresses return false', () async {
      expect(
        await container
            .read(addressParserProvider)
            .isValidAddressForAsset(address: '', asset: Asset.btc()),
        false,
      );
      expect(
        await container.read(addressParserProvider).isValidAddressForAsset(
            address: '1111118Vm8AvDr9Bkvij6UfVR7MerCyrz3KS3h4,.,.,.,,.,',
            asset: Asset.btc()),
        false,
      );
      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
              asset: Asset.btc()),
          false);
    });

    test('bech32 addresses return true', () async {
      expect(
        await container.read(addressParserProvider).isValidAddressForAsset(
            address: 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
            asset: Asset.btc()),
        true,
      );
      expect(
        await container.read(addressParserProvider).isValidAddressForAsset(
            address:
                'bc1qc7slrfxkknqcq2jevvvkdgvrt8080852dfjewde450xdlk4ugp7szw5tk9',
            asset: Asset.btc()),
        true,
      );
    });

    test('P2PKH addresses return true', () async {
      expect(
        await container.read(addressParserProvider).isValidAddressForAsset(
            address: '18Vm8AvDr9Bkvij6UfVR7MerCyrz3KS3h4', asset: Asset.btc()),
        true,
      );

      expect(
        await container.read(addressParserProvider).isValidAddressForAsset(
            address: '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2', asset: Asset.btc()),
        true,
      );
    });
    test('P2SH addresses return true', () async {
      expect(
        await container.read(addressParserProvider).isValidAddressForAsset(
            address: '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy', asset: Asset.btc()),
        true,
      );
    });

    test('P3TR (taproot) addresses return false', () async {
      expect(
          await container.read(addressParserProvider).isValidAddressForAsset(
              address:
                  'bc1p8denc9m4sqe9hluasrvxkkdqgkydrk5ctxre5nkk4qwdvefn0sdsc6eqxe',
              asset: Asset.btc()),
          false);
    });
  }, skip: true);
  group('BIP21', () {
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
        equals(Asset.usdtEth()));
    expect(
        await container.read(addressParserProvider).parseAsset(
              address: 'TNPeeaaFB7K9cmo4uQpcU32zGK8G1NYqeL',
            ),
        equals(Asset.usdtTrx()));
  }, skip: true);
}
