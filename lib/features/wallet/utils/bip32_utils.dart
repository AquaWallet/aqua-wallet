import 'dart:convert';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:crypto/crypto.dart';
import 'package:coin_cz/logger.dart';

/// Generates a BIP32 fingerprint from a mnemonic phrase
///
/// The fingerprint is the first 4 bytes of the HASH160 of the public key,
/// which is a standard way to identify HD wallets in the Bitcoin ecosystem.
///
/// Returns the fingerprint as a hexadecimal string.
String generateBip32Fingerprint(String mnemonic) {
  try {
    // Convert mnemonic to seed
    final seed = bip39.mnemonicToSeed(mnemonic);

    // Derive master key from seed
    final masterKey = bip32.BIP32.fromSeed(seed);

    // Get fingerprint (first 4 bytes of the HASH160 of the public key)
    final fingerprint = masterKey.fingerprint;

    // Convert to hex string
    final fingerprintHex = HEX.encode(fingerprint);

    return fingerprintHex;
  } catch (e) {
    logger.error('Error generating BIP32 fingerprint: $e');
    // Fallback to a hash-based approach if BIP32 library fails
    final bytes = utf8.encode(mnemonic);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8); // Take first 8 chars of hash
  }
}

/// Validates if a string is a valid BIP32 fingerprint
///
/// A valid fingerprint is an 8-character hexadecimal string.
bool isValidBip32Fingerprint(String fingerprint) {
  if (fingerprint.length != 8) return false;

  // Check if all characters are valid hexadecimal
  return RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(fingerprint);
}
