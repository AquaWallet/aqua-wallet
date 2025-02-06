import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/user/user_hash_id_provider.dart';

class MockBitcoinProvider extends Mock implements BitcoinProvider {}

void main() {
  late ProviderContainer container;
  late MockBitcoinProvider mockBitcoinProvider;

  setUp(() {
    mockBitcoinProvider = MockBitcoinProvider();
    container = ProviderContainer(
      overrides: [
        bitcoinProvider.overrideWithValue(mockBitcoinProvider),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('generates correct hash from zpub', () async {
    // Arrange
    const testZpub = 'zpub123test';
    // Expected hash for 'zpub123test'
    const expectedHash =
        'a9b519af950ed1fe301c94bcacb30338596c76ca73e803d5247bb4590d25e1e9';

    const subaccount = GdkSubaccount(
      type: GdkSubaccountTypeEnum.type_p2wpkh,
      slip132ExtendedPubkey: testZpub,
    );

    when(() => mockBitcoinProvider.getSubaccounts())
        .thenAnswer((_) async => [subaccount]);

    // Act
    final result = await container.read(userHashIdProvider.future);

    // Assert
    expect(result, expectedHash);
    verify(() => mockBitcoinProvider.getSubaccounts()).called(1);
  });

  test('throws StateError when no BIP84 subaccount found', () async {
    // Arrange
    const nonBip84Subaccount = GdkSubaccount(
      type: GdkSubaccountTypeEnum.type_p2pkh,
      slip132ExtendedPubkey: 'xpub123',
    );

    when(() => mockBitcoinProvider.getSubaccounts())
        .thenAnswer((_) async => [nonBip84Subaccount]);

    // Act & Assert
    expect(
      () => container.read(userHashIdProvider.future),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        'No BIP84 subaccount found',
      )),
    );
  });

  test('throws StateError when subaccounts is null', () {
    // Arrange
    when(() => mockBitcoinProvider.getSubaccounts())
        .thenAnswer((_) async => null);

    // Act & Assert
    expect(
      () => container.read(userHashIdProvider.future),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        'Bitcoin subaccounts not available',
      )),
    );
  });

  test('throws StateError when zpub is null', () async {
    // Arrange
    const subaccount = GdkSubaccount(
      type: GdkSubaccountTypeEnum.type_p2wpkh,
      slip132ExtendedPubkey: null,
    );

    when(() => mockBitcoinProvider.getSubaccounts())
        .thenAnswer((_) async => [subaccount]);

    // Act & Assert
    expect(
      () => container.read(userHashIdProvider.future),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        'No zpub available for BIP84 subaccount',
      )),
    );
  });
}
