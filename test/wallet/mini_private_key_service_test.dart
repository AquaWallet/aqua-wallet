import 'package:aqua/features/wallet/utils/mini_private_key_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final miniPrivateKeyService = MiniPrivateKeyService();

  group('MiniPrivateKeyService', () {
    test('should validate a well-formed mini private key', () {
      const validMiniKey = 'S6c56bnXQiBjk9mqSYE7ykVQ7NzrRy';
      expect(miniPrivateKeyService.isValidMiniPrivateKey(validMiniKey), isTrue);
    });

    test('should invalidate a malformed mini private key', () {
      const invalidMiniKey =
          'S6c56bnXQiBjk9mqSYE7ykVQ7NzrRz'; // Changed last character
      expect(
          miniPrivateKeyService.isValidMiniPrivateKey(invalidMiniKey), isFalse);
    });

    test('should convert a valid mini private key to a full private key', () {
      const validMiniKey = 'S6c56bnXQiBjk9mqSYE7ykVQ7NzrRy';
      final fullPrivateKey =
          miniPrivateKeyService.getFullPrivateKey(validMiniKey);
      expect(fullPrivateKey, isNotNull);
      expect(fullPrivateKey?.length, 64); // SHA256 hash length in hex
    });

    test('should return null for an invalid mini private key conversion', () {
      const invalidMiniKey =
          'S6c56bnXQiBjk9mqSYE7ykVQ7NzrRz'; // Changed last character
      final fullPrivateKey =
          miniPrivateKeyService.getFullPrivateKey(invalidMiniKey);
      expect(fullPrivateKey, isNull);
    });
  });
}
