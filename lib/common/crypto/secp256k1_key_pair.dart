import 'package:aqua/common/crypto/generate_random_bytes.dart';
import "package:pointycastle/export.dart";
import 'package:convert/convert.dart';

AsymmetricKeyPair<PublicKey, PrivateKey> secp256k1KeyPair() {
  var keyParams = ECKeyGeneratorParameters(ECCurve_secp256k1());

  var random = FortunaRandom();
  random.seed(KeyParameter(generateRandom32Bytes()));

  var generator = ECKeyGenerator();
  generator.init(ParametersWithRandom(keyParams, random));

  return generator.generateKeyPair();
}

String publicKeyToHex(ECPublicKey publicKey) {
  List<int> publicKeyBytes = publicKey.Q!.getEncoded();
  final keyHex = hex.encode(publicKeyBytes);
  return keyHex;
}

String privateKeyToHex(ECPrivateKey privateKey) {
  final keyHex = privateKey.d!.toRadixString(16);
  return keyHex;
}
