import 'package:aqua/common/crypto/generate_random_bytes.dart';
import "package:pointycastle/export.dart";
import 'package:convert/convert.dart';

AsymmetricKeyPair<PublicKey, PrivateKey> secp256k1KeyPair() {
  final keyParams = ECKeyGeneratorParameters(ECCurve_secp256k1());

  final random = FortunaRandom();
  random.seed(KeyParameter(generateRandom32Bytes()));

  final generator = ECKeyGenerator();
  generator.init(ParametersWithRandom(keyParams, random));

  return generator.generateKeyPair();
}

String publicKeyToHex(ECPublicKey publicKey) {
  List<int> publicKeyBytes = publicKey.Q!.getEncoded();
  final keyHex = hex.encode(publicKeyBytes);
  return keyHex;
}

String privateKeyToHex(ECPrivateKey privateKey) {
  // BigInt.toRadixString will truncate leading zeros, so re-pad if necessary
  final keyHex = privateKey.d!.toRadixString(16);
  final paddedKeyHex = keyHex.padLeft(64, '0');
  return paddedKeyHex;
}
