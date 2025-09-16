import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'env_provider.freezed.dart';

class EnvPrefKeys {
  static const env = 'env';
}

//ANCHOR - Main Provider

enum Env { mainnet, testnet, regtest }

final envProvider = StateNotifierProvider<EnvNotifier, Env>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return EnvNotifier(prefs);
});

class EnvNotifier extends StateNotifier<Env> {
  final SharedPreferences _prefs;

  EnvNotifier(this._prefs) : super(_initialEnv(_prefs));

  static Env _initialEnv(SharedPreferences prefs) {
    final envString = prefs.getString(EnvPrefKeys.env);
    if (envString != null && Env.values.any((e) => e.toString() == envString)) {
      return Env.values.firstWhere((e) => e.toString() == envString);
    }
    return Env.mainnet;
  }

  Future<void> setEnv(Env env) async {
    await _prefs.setString(EnvPrefKeys.env, env.toString());
    state = env;
  }
}

//ANCHOR - Config Model

@freezed
class EnvConfig with _$EnvConfig {
  const factory EnvConfig({
    required String apiUrl,
    required String apiKey,
    String? username,
    String? password,
    String? secret,
  }) = _EnvConfig;
}

// ANCHOR - Meld

final meldEnvConfigProvider = Provider<EnvConfig>((ref) {
  final env = ref.watch(envProvider);

  switch (env) {
    case Env.mainnet:
      return EnvConfig(
        apiUrl: meldProdUrl,
        apiKey: Secrets.kMeldProdPublicKey,
      );
    case Env.testnet || Env.regtest:
      return EnvConfig(
        apiUrl: meldSandboxUrl,
        apiKey: Secrets.kMeldSandboxPublicKey,
      );
    default:
      throw UnimplementedError('Unknown environment');
  }
});

// ANCHOR - Boltz

final boltzEnvConfigProvider = Provider<EnvConfig>((ref) {
  final env = ref.watch(envProvider);

  switch (env) {
    case Env.mainnet:
      return const EnvConfig(
        apiUrl: boltzV2MainnetUrl,
        apiKey: '',
      );
    case Env.testnet || Env.regtest:
      return const EnvConfig(
        apiUrl: boltzV2TestnetUrl,
        apiKey: '',
      );
    default:
      throw UnimplementedError('Unknown environment');
  }
});

// ANCHOR - Boltz

final sideswapEnvConfigProvider = Provider<EnvConfig>((ref) {
  final env = ref.watch(envProvider);

  switch (env) {
    case Env.mainnet:
      return const EnvConfig(
        apiUrl: sideswapMainnetUrl,
        apiKey: kSideswapApiKey,
      );
    case Env.testnet || Env.regtest:
      return const EnvConfig(
        apiUrl: sideswapTestnetUrl,
        apiKey: kSideswapApiKey,
      );
    default:
      throw UnimplementedError('Unknown environment');
  }
});

// ANCHOR - Aqua Service

final aquaServiceEnvConfigProvider = Provider<EnvConfig>((ref) {
  final env = ref.watch(envProvider);

  switch (env) {
    case Env.mainnet:
      return const EnvConfig(
        apiUrl: mainNetAssetsUrl,
        apiKey: '',
      );
    case Env.testnet || Env.regtest:
      return const EnvConfig(
        apiUrl: testNetAssetsUrl,
        apiKey: '',
      );
    default:
      throw UnimplementedError('Unknown environment');
  }
});
