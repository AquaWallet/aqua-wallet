import 'package:aqua/config/constants/lightning_providers.dart';
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
  static const submarineProviderName = 'submarine-ln-provider-name';
  static const reverseProviderName = 'reverse-ln-provider-name';
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

  /// Configured provider name for the given swap type, or null when the
  /// config does not carry one. Unlike the URL, a missing name is not fatal —
  /// callers fall back to [currentLnProviderName].
  String? lnProviderNameOrNull(SwapType swapType) {
    final key = switch (swapType) {
      SwapType.submarine => BoltzBaseUrlKeys.submarineProviderName,
      SwapType.reverse => BoltzBaseUrlKeys.reverseProviderName,
      SwapType.chain => null,
    };
    final name = key == null ? null : baseUrls[key];
    return (name == null || name.isEmpty) ? null : name;
  }
}

// ANCHOR - Boltz hosts

final boltzSetupConfigProvider = FutureProvider.autoDispose<SetupConfig>(
  (ref) => fetchSetupConfig(ref),
);

/// API host serving the given swap type in the current environment.
final boltzApiUrlProvider = AsyncNotifierProvider.autoDispose
    .family<BoltzApiUrlNotifier, String, SwapType>(
  BoltzApiUrlNotifier.new,
);

class BoltzApiUrlNotifier
    extends AutoDisposeFamilyAsyncNotifier<String, SwapType> {
  @override
  Future<String> build(SwapType arg) async {
    final setup = await _requireSetupConfig(ref);
    return setup.requireBoltzApiUrl(ref.watch(envProvider), arg);
  }
}

/// A setup config we cannot fetch leaves us without a host to talk to, which is
/// indistinguishable to the user from a host that is down, so both reach the UI
/// as the same unavailable prompt.
Future<SetupConfig> _requireSetupConfig(AutoDisposeRef ref) =>
    requireBoltzService(() => ref.watch(boltzSetupConfigProvider.future));

// ANCHOR - Provider naming

/// Name of the provider serving the given swap type now, read from the setup
/// config Ankara serves. Falls back to [currentLnProviderName] while the
/// config has not loaded or does not carry a name key.
final currentLnProviderNameProvider =
    Provider.family<String, SwapType>((ref, type) {
  final setup = ref.watch(setupConfigProvider).valueOrNull;
  return setup?.lnProviderNameOrNull(type) ?? currentLnProviderName;
});

/// Name of the provider serving the given swap type now, read from the host
/// Ankara configures. Screens that run before a swap exists have no stored URL
/// to name a provider from, so they name this instead.
final lnProviderNameProvider =
    Provider.autoDispose.family<String, SwapType>((ref, type) {
  final currentName = ref.watch(currentLnProviderNameProvider(type));
  final url = ref.watch(boltzApiUrlProvider(type)).valueOrNull;
  // A config we have not fetched yet is not a v0 swap, so it must not fall
  // through to the legacy name the way a missing stored URL does.
  return url == null
      ? currentName
      : lnProviderNameForApiUrl(url, currentName: currentName);
});
