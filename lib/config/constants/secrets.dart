import 'package:envied/envied.dart';

part 'secrets.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Secrets {
  @EnviedField(varName: 'MELD_PROD_PUBLIC_KEY')
  static final String kMeldProdPublicKey = _Secrets.kMeldProdPublicKey;
  @EnviedField(varName: 'MELD_SANDBOX_PUBLIC_KEY')
  static final String kMeldSandboxPublicKey = _Secrets.kMeldSandboxPublicKey;
}
