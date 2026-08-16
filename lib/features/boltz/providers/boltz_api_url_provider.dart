import 'package:aqua/features/boltz/models/boltz_exceptions.dart';
import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:aqua/features/feature_flags/providers/setup_config_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:boltz/boltz.dart';

// ANCHOR - Boltz base URL keys (Ankara setup base_urls)

class BoltzBaseUrlKeys {
  static const submarineMainnet = 'submarine-ln-swaps-mainnet';
  static const submarineTestnet = 'submarine-ln-swaps-testnet';
  static const reverseMainnet = 'reverse-ln-swaps-mainnet';
  static const reverseTestnet = 'reverse-ln-swaps-testnet';
}

extension SetupConfigBoltzUrls on SetupConfig {
  String requireBoltzApiUrl(Env env, SwapType swapType) {
    final key = switch ((env, swapType)) {
      (Env.mainnet, SwapType.submarine) => BoltzBaseUrlKeys.submarineMainnet,
      (Env.testnet || Env.regtest, SwapType.submarine) =>
        BoltzBaseUrlKeys.submarineTestnet,
      (Env.mainnet, SwapType.reverse) => BoltzBaseUrlKeys.reverseMainnet,
      (Env.testnet || Env.regtest, SwapType.reverse) =>
        BoltzBaseUrlKeys.reverseTestnet,
      (_, SwapType.chain) => throw BoltzException(
          BoltzExceptionType.serviceUnavailable,
        ),
    };
    return _requireUrl(key);
  }

  String _requireUrl(String key) {
    final url = baseUrls[key];
    if (url == null || url.isEmpty) {
      throw BoltzException(BoltzExceptionType.serviceUnavailable);
    }
    return url;
  }
}

// ANCHOR - Boltz hosts

/// API host serving the given swap type in the current environment.
final boltzApiUrlProvider =
    AsyncNotifierProvider.family<BoltzApiUrlNotifier, String, SwapType>(
  BoltzApiUrlNotifier.new,
);

class BoltzApiUrlNotifier extends FamilyAsyncNotifier<String, SwapType> {
  @override
  Future<String> build(SwapType arg) async {
    final setup = await _requireSetupConfig(ref);
    return setup.requireBoltzApiUrl(ref.watch(envProvider), arg);
  }
}

/// A setup config we cannot fetch leaves us without a host to talk to, which is
/// indistinguishable to the user from a host that is down, so both reach the UI
/// as the same unavailable prompt.
Future<SetupConfig> _requireSetupConfig(Ref ref) =>
    requireBoltzService(() => ref.watch(setupConfigProvider.future));
