import 'package:envied/envied.dart';

part 'secrets.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Secrets {
  @EnviedField(varName: 'MELD_PROD_PUBLIC_KEY')
  static final String kMeldProdPublicKey = _Secrets.kMeldProdPublicKey;
  @EnviedField(varName: 'MELD_SANDBOX_PUBLIC_KEY')
  static final String kMeldSandboxPublicKey = _Secrets.kMeldSandboxPublicKey;
  @EnviedField(varName: 'BTC_DIRECT_SANDBOX_USERNAME')
  static final String kBtcDirectSandboxUsername =
      _Secrets.kBtcDirectSandboxUsername;
  @EnviedField(varName: 'BTC_DIRECT_SANDBOX_PASSWORD')
  static final String kBtcDirectSandboxPassword =
      _Secrets.kBtcDirectSandboxPassword;
  @EnviedField(varName: 'BTC_DIRECT_SANDBOX_API_KEY')
  static final String kBtcDirectSandboxApiKey =
      _Secrets.kBtcDirectSandboxApiKey;
  @EnviedField(varName: 'BTC_DIRECT_SANDBOX_SECRET')
  static final String kBtcDirectSandboxSecret =
      _Secrets.kBtcDirectSandboxSecret;
  @EnviedField(varName: 'BTC_DIRECT_PROD_USERNAME')
  static final String kBtcDirectProdUsername = _Secrets.kBtcDirectProdUsername;
  @EnviedField(varName: 'BTC_DIRECT_PROD_PASSWORD')
  static final String kBtcDirectProdPassword = _Secrets.kBtcDirectProdPassword;
  @EnviedField(varName: 'BTC_DIRECT_PROD_API_KEY')
  static final String kBtcDirectProdApiKey = _Secrets.kBtcDirectProdApiKey;
  @EnviedField(varName: 'BTC_DIRECT_PROD_SECRET')
  static final String kBtcDirectProdSecret = _Secrets.kBtcDirectProdSecret;
}
