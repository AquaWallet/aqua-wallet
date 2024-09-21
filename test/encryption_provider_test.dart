import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

const kFakeMnemonic = 'this is a fake mnemonic';
const kTestString = 'this is a test string';

class MockSecureStorageProvider extends Mock implements IStorage {}

void main() {
  final mockSecureStorageProvider = MockSecureStorageProvider();

  final container = ProviderContainer(overrides: [
    secureStorageProvider.overrideWithValue(mockSecureStorageProvider),
  ]);

  group('EncryptionProvider', () {
    test(
      'should throw exception when secure storage fails to provide mnemonic',
      () async {
        when(() => mockSecureStorageProvider.get(StorageKeys.mnemonic))
            .thenAnswer(
                (_) async => Future.value((null, StorageError('Failed'))));

        expect(
          () => container.read(encryptionProvider.future),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get mnemonic from secure storage'),
          )),
        );
      },
    );

    test('should encrypt given text in a deterministic way', () async {
      when(() => mockSecureStorageProvider.get(StorageKeys.mnemonic))
          .thenAnswer((_) async => Future.value((kFakeMnemonic, null)));

      final encryption1 = await container.read(encryptionProvider.future);
      final encryption2 = await container.read(encryptionProvider.future);

      final encrypted1 = encryption1.encrypt(kTestString);
      final encrypted2 = encryption2.encrypt(kTestString);
      debugPrint('Encrypted1: $encrypted1');
      debugPrint('Encrypted2: $encrypted2');

      expect(encrypted1, equals(encrypted2));

      final decrypted1 = encryption1.decrypt(encrypted1);
      final decrypted2 = encryption2.decrypt(encrypted2);
      debugPrint('Decrypted1: $decrypted1');
      debugPrint('Decrypted2: $decrypted2');

      expect(decrypted1, equals(kTestString));
      expect(decrypted2, equals(kTestString));
    });
  });
}
