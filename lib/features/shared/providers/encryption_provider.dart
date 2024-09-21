import 'dart:convert';
import 'dart:typed_data';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart' hide Key;
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

final encryptionProvider = FutureProvider.autoDispose<Encryption>((ref) async {
  final (mnemonic, err) =
      await ref.read(secureStorageProvider).get(StorageKeys.mnemonic);
  if (err != null || mnemonic == null) {
    throw Exception('Failed to get mnemonic from secure storage');
  }

  final mnemonicSha256 = sha256.convert(utf8.encode(mnemonic));
  final keyBytes = Uint8List.fromList(mnemonicSha256.bytes);
  //FIXME - Using a fixed salt for now, should be less obvious & not hardcoded
  final key = Key(keyBytes).stretch(32, salt: utf8.encode('aqua'));
  final iv = IV.fromSecureRandom(32);

  return _Encryption(
    encrypter: Encrypter(AES(key, mode: AESMode.gcm)),
    vector: iv,
  );
});

abstract class Encryption {
  String encrypt(String text);
  String decrypt(String encrypted);
}

class _Encryption implements Encryption {
  _Encryption({
    required this.encrypter,
    required this.vector,
  });

  final Encrypter encrypter;
  final IV vector;

  @override
  String encrypt(String text) {
    return encrypter.encrypt(text, iv: vector).base64;
  }

  @override
  String decrypt(String encrypted) {
    return encrypter.decrypt64(encrypted, iv: vector);
  }
}
