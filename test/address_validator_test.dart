import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final container = ProviderContainer();

  group('Bitcoin', () {
    test('invalid addresses return false', () {
      expect(
        container
            .read(addressParserProvider)
            .isValidAddressForAsset(address: '', asset: Asset.btc()),
        false,
      );
      expect(
        container.read(addressParserProvider).isValidAddressForAsset(
            address: '1111118Vm8AvDr9Bkvij6UfVR7MerCyrz3KS3h4,.,.,.,,.,',
            asset: Asset.btc()),
        false,
      );
      expect(
          container.read(addressParserProvider).isValidAddressForAsset(
              address: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
              asset: Asset.btc()),
          false);
    });

    test('bech32 addresses return true', () {
      expect(
        container.read(addressParserProvider).isValidAddressForAsset(
            address: 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
            asset: Asset.btc()),
        true,
      );
      expect(
        container.read(addressParserProvider).isValidAddressForAsset(
            address:
                'bc1qc7slrfxkknqcq2jevvvkdgvrt8080852dfjewde450xdlk4ugp7szw5tk9',
            asset: Asset.btc()),
        true,
      );
    });

    test('P2PKH addresses return true', () {
      expect(
        container.read(addressParserProvider).isValidAddressForAsset(
            address: '18Vm8AvDr9Bkvij6UfVR7MerCyrz3KS3h4', asset: Asset.btc()),
        true,
      );

      expect(
        container.read(addressParserProvider).isValidAddressForAsset(
            address: '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2', asset: Asset.btc()),
        true,
      );
    });
    test('P2SH addresses return true', () {
      expect(
        container.read(addressParserProvider).isValidAddressForAsset(
            address: '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy', asset: Asset.btc()),
        true,
      );
    });

    test('P3TR addresses return false', () {
      expect(
          container.read(addressParserProvider).isValidAddressForAsset(
              address:
                  'bc1p8denc9m4sqe9hluasrvxkkdqgkydrk5ctxre5nkk4qwdvefn0sdsc6eqxe',
              asset: Asset.btc()),
          false);
    });
  }, skip: true);

  test('Ethereum address', () {
    expect(
        container.read(addressParserProvider).isValidAddressForAsset(
            address: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
            asset: Asset.usdtEth()),
        true);
  }, skip: true);

  test('Tron address', () {
    expect(
        container.read(addressParserProvider).isValidAddressForAsset(
            address: 'TNPeeaaFB7K9cmo4uQpcU32zGK8G1NYqeL',
            asset: Asset.usdtTrx()),
        true);
  }, skip: true);

  test('check for all supported assets', () {
    expect(
      container.read(addressParserProvider).isValidAddress(
            address: '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy',
          ),
      true,
    );
    expect(
        container.read(addressParserProvider).isValidAddress(
              address: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
            ),
        true);
    expect(
        container.read(addressParserProvider).isValidAddress(
              address: 'TNPeeaaFB7K9cmo4uQpcU32zGK8G1NYqeL',
            ),
        true);
  }, skip: true);
}
