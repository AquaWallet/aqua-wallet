import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/address_validator/address_validator.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLiquidProvider extends Mock implements LiquidProvider {}

class MockBitcoinProvider extends Mock implements BitcoinProvider {}

void main() {
  final mockLiquidProvider = MockLiquidProvider();
  final mockBitcoinProvider = MockBitcoinProvider();

  // we call gdk for `isValidAddress` for liquid and bitcoin, so no need to test
  when(() => mockLiquidProvider.isValidAddress(any()))
      .thenAnswer((_) async => true);
  when(() => mockBitcoinProvider.isValidAddress(any()))
      .thenAnswer((_) async => true);

  final container = ProviderContainer(overrides: [
    liquidProvider.overrideWithValue(mockLiquidProvider),
    bitcoinProvider.overrideWithValue(mockBitcoinProvider),
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
