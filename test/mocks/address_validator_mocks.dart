import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:mocktail/mocktail.dart';

class MockAddressParserProvider extends Mock implements AddressParser {}

extension MockAddressParserProviderX on MockAddressParserProvider {
  void mockIsValidAddressForAssetCall({required bool value}) {
    when(() => isValidAddressForAsset(
          asset: any(named: 'asset'),
          address: any(named: 'address'),
          accountForCompatibleAssets: any(named: 'accountForCompatibleAssets'),
        )).thenAnswer((_) => Future.value(value));
  }

  void mockParseInputCall({ParsedAddress? value}) {
    when(() => parseInput(
          input: any(named: 'input'),
          asset: any(named: 'asset'),
        )).thenAnswer((_) => Future.value(value));
  }

  void mockThrowParseInputCall({required String message}) {
    when(() => parseInput(
          input: any(named: 'input'),
          asset: any(named: 'asset'),
        )).thenThrow((_) => Future.value(Exception(message)));
  }
}
