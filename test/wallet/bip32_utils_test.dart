import 'package:flutter_test/flutter_test.dart';
import 'package:aqua/features/wallet/utils/bip32_utils.dart';
import 'package:bip39/bip39.dart' as bip39;

void main() {
  group('BIP32 Utils Tests', () {
    test('should generate consistent fingerprint from mnemonic', () {
      // Use a test mnemonic (DO NOT USE IN PRODUCTION)
      const testMnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

      // Generate fingerprint
      final fingerprint = generateBip32Fingerprint(testMnemonic);

      // Verify it's a valid fingerprint
      expect(isValidBip32Fingerprint(fingerprint), true);

      // Verify length is correct (8 characters for 4 bytes in hex)
      expect(fingerprint.length, 8);

      // Generate again and verify it's the same (deterministic)
      final fingerprint2 = generateBip32Fingerprint(testMnemonic);
      expect(fingerprint, equals(fingerprint2));
    });

    test('should generate different fingerprints for different mnemonics', () {
      // Two different test mnemonics
      const mnemonic1 =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const mnemonic2 = 'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong';

      // Generate fingerprints
      final fingerprint1 = generateBip32Fingerprint(mnemonic1);
      final fingerprint2 = generateBip32Fingerprint(mnemonic2);

      // Verify they're different
      expect(fingerprint1, isNot(equals(fingerprint2)));
    });

    test('should validate fingerprint format correctly', () {
      // Valid fingerprints
      expect(isValidBip32Fingerprint('abcdef12'), true);
      expect(isValidBip32Fingerprint('12345678'), true);
      expect(isValidBip32Fingerprint('ABCDEF12'), true);

      // Invalid fingerprints
      expect(isValidBip32Fingerprint(''), false); // Empty
      expect(isValidBip32Fingerprint('123456'), false); // Too short
      expect(isValidBip32Fingerprint('123456789'), false); // Too long
      expect(isValidBip32Fingerprint('abcdefgh'), false); // Non-hex characters
      expect(isValidBip32Fingerprint('12-34567'), false); // Special characters
    });

    test('should handle edge cases gracefully', () {
      // Empty mnemonic (should not crash, but result may not be valid BIP32)
      final emptyResult = generateBip32Fingerprint('');
      expect(emptyResult.length,
          8); // Should still return something of correct length

      // Invalid mnemonic (not in wordlist)
      final invalidResult =
          generateBip32Fingerprint('not a valid mnemonic phrase');
      expect(invalidResult.length,
          8); // Should still return something of correct length
    });

    test('should work with randomly generated valid mnemonics', () {
      // Generate a random valid mnemonic
      final randomMnemonic = bip39.generateMnemonic();

      // Generate fingerprint
      final fingerprint = generateBip32Fingerprint(randomMnemonic);

      // Verify it's valid
      expect(isValidBip32Fingerprint(fingerprint), true);
      expect(fingerprint.length, 8);
    });
  });
}
