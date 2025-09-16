import 'dart:convert';
import 'dart:typed_data';
import 'package:coin_cz/logger.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:coin_cz/features/wallet/models/ext_priv_key_exceptions.dart';

// https://en.bitcoin.it/wiki/Mini_private_key_format#Decoding
class MiniPrivateKeyService {
  static const String base58Alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  /// Validates if the given mini private key is well-formed.
  bool isValidMiniPrivateKey(String miniKey) {
    if (miniKey.length != 30 || !miniKey.startsWith('S')) {
      return false;
    }

    final testKey = '$miniKey?';
    final hash = sha256.convert(utf8.encode(testKey)).bytes;

    return hash[0] == 0x00;
  }

  /// Converts a valid mini private key to a full 256-bit private key.
  String? getFullPrivateKey(String miniKey) {
    if (!isValidMiniPrivateKey(miniKey)) {
      logger.debug('Invalid mini private key!');
      return null;
    }

    final hash = sha256.convert(utf8.encode(miniKey)).bytes;
    return hash.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Converts a mini private key to a WIF (Wallet Import Format) private key.
  String miniKeyToWIF(String miniKey, {bool compressed = true}) {
    // Validate the mini key
    if (!isValidMiniPrivateKey(miniKey)) {
      logger.debug('Invalid mini private key!');
      throw MiniPrivateKeyException(MiniPrivateKeyExceptionType.invalidMiniKey);
    }

    // Convert mini key to full private key
    final fullPrivateKey = getFullPrivateKey(miniKey);
    if (fullPrivateKey == null) {
      throw MiniPrivateKeyException(MiniPrivateKeyExceptionType.invalidMiniKey);
    }

    logger.debug('Full private key (hex): $fullPrivateKey');

    // Convert full private key to WIF
    final privateKeyBytes = List<int>.generate(
      fullPrivateKey.length ~/ 2,
      (i) => int.parse(fullPrivateKey.substring(i * 2, i * 2 + 2), radix: 16),
    );

    final extendedKey = [0x80] + privateKeyBytes; // 0x80 for mainnet

    if (compressed) {
      extendedKey.add(0x01);
    }

    logger.debug('Extended key length: ${extendedKey.length}');

    // Create new digest instances for each hash operation
    final firstSha = SHA256Digest().process(Uint8List.fromList(extendedKey));
    final secondSha = SHA256Digest().process(firstSha);
    final checksum = secondSha.sublist(0, 4);

    final finalKey = Uint8List.fromList(extendedKey + checksum);
    final wif = Base58.encode(finalKey);

    logger.debug('WIF length: ${wif.length}');
    logger.debug('WIF compressed: $compressed');

    return wif;
  }
}

class Base58 {
  static const String alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  static String encode(Uint8List bytes) {
    BigInt intData = BigInt.parse(
        '0${bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}',
        radix: 16);

    String result = '';
    while (intData > BigInt.zero) {
      final mod = intData % BigInt.from(58);
      result = alphabet[mod.toInt()] + result;
      intData = intData ~/ BigInt.from(58);
    }

    for (final byte in bytes) {
      if (byte == 0) {
        result = alphabet[0] + result;
      } else {
        break;
      }
    }

    return result;
  }
}
