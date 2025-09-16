import 'package:coin_cz/data/backend/bitcoin_network.dart';
import 'package:coin_cz/data/models/gdk_models.dart';
import 'package:coin_cz/data/provider/network_frontend.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';

final bitcoinProvider = Provider<BitcoinProvider>((ref) => BitcoinProvider(
      ref: ref,
      session: BitcoinNetwork(),
    ));

class BitcoinProvider extends NetworkFrontend {
  BitcoinProvider({required super.ref, required super.session});

  /// mainnet:
  /// mainnet
  ///
  /// testnet:
  /// testnet
  ///
  /// rust
  /// gdk mainnet:
  /// electrum-mainnet
  ///
  /// gdk testnet:
  /// electrum-testnet
  ///
  /// https://github.com/Blockstream/gdk/blob/master/src/network_parameters.cpp
  @override
  Future<bool> connect({
    GdkConnectionParams? params,
  }) async {
    final env = ref.read(envProvider);
    switch (env) {
      case Env.testnet:
        networkName = 'electrum-testnet';
      case Env.regtest || Env.mainnet:
        networkName = 'electrum-mainnet';
    }
    logger.info("[ENV] $env - using bitcoin network: $networkName");

    final electrumConfig = ref.read(electrumServerProvider);
    if (electrumConfig.isCustomElectrumServer) {
      final networkRegistered = await super.registerNetwork(
        GdkRegisterNetworkData(
          name: networkName,
          networkDetails: GdkNetwork(
            electrumUrl: electrumConfig.customElectrumServerBtcUrl,
          ),
        ),
      );

      if (!networkRegistered) {
        logger.error('[$runtimeType] Registering network $networkName failed!');
        return false;
      }
    }

    params ??= GdkConnectionParams(name: networkName);
    return super.connect(params: params);
  }

  Future<void> onBackendError(dynamic error) async {
    logger.error('[$runtimeType] Bitcoin backend error: $error');
  }

  @override
  Future<bool> init() async {
    logger.debug('[$runtimeType] Initializing bitcoin backend');
    final result = await super.init();

    if (!result) {
      throw InitializeNetworkFrontendException();
    }

    logger.debug('[$runtimeType] Bitcoin backend initialized: $result');

    return result;
  }

  @override
  Future<int> minFeeRate() async {
    return 1000;
  }
}
