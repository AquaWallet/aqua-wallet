import 'dart:typed_data';
import 'package:aqua/features/wallet/utils/mini_private_key_service.dart';
import 'package:aqua/logger.dart';
import 'package:pointycastle/digests/sha256.dart';

/// Validates a Tron address using Base58Check decoding and checksum verification.
///
/// Tron addresses use Base58Check encoding with the following structure:
/// - 1 byte version (0x41 for mainnet, resulting in 'T' prefix)
/// - 20 bytes address
/// - 4 bytes checksum (double SHA256 of version + address)
///
/// Returns true if the address is valid, false otherwise.
bool isValidTronAddressWithChecksum(String address) {
  try {
    // Quick format check: must start with 'T' and be 34 characters
    if (!address.startsWith('T') || address.length != 34) {
      return false;
    }

    // Decode Base58
    final decoded = Base58.decode(address);
    if (decoded == null) {
      return false;
    }

    // Must decode to exactly 25 bytes
    if (decoded.length != 25) {
      return false;
    }

    // Check version byte (0x41 for mainnet)
    if (decoded[0] != 0x41) {
      return false;
    }

    // Extract address (bytes 1-20) and checksum (bytes 21-24)
    final versionAndAddress = decoded.sublist(0, 21); // version + address
    final storedChecksum = decoded.sublist(21, 25);

    // Compute checksum: double SHA256 of version + address
    final firstHash =
        SHA256Digest().process(Uint8List.fromList(versionAndAddress));
    final secondHash = SHA256Digest().process(firstHash);
    final computedChecksum = secondHash.sublist(0, 4);

    // Verify checksum matches
    if (!_bytesEqual(storedChecksum, computedChecksum)) {
      return false;
    }

    return true;
  } catch (e) {
    logger.debug('Error validating Tron address: $e');
    return false;
  }
}

/// Validates a Solana address using Base58 decoding.
///
/// Solana addresses use raw Base58 encoding (no checksum) and decode to
/// exactly 32 bytes (an Ed25519 public key).
///
/// Returns true if the address is valid, false otherwise.
bool isValidSolanaAddressWithDecode(String address) {
  try {
    // Quick format check: must be 32-44 base58 characters
    if (address.isEmpty || address.length < 32 || address.length > 44) {
      return false;
    }

    // Decode Base58
    final decoded = Base58.decode(address);
    if (decoded == null) {
      return false;
    }

    // Must decode to exactly 32 bytes (Ed25519 public key)
    if (decoded.length != 32) {
      return false;
    }

    return true;
  } catch (e) {
    logger.debug('Error validating Solana address: $e');
    return false;
  }
}

/// Helper function to compare two byte arrays for equality.
bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
