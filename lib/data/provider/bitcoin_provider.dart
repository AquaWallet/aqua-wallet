import 'package:aqua/data/backend/bitcoin_network.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

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
    logger.i("[ENV] $env - using bitcoin network: $networkName");

    params ??= GdkConnectionParams(name: networkName);
    return super.connect(params: params);
  }

  Future<void> onBackendError(dynamic error) async {
    logger.e('[$runtimeType] Bitcoin backend error: $error');
  }

  @override
  Future<bool> init() async {
    logger.d('[$runtimeType] Initializing bitcoin backend');
    final result = await super.init();

    if (!result) {
      throw InitializeNetworkFrontendException();
    }

    logger.d('[$runtimeType] Bitcoin backend initialized: $result');

    return result;
  }

  @override
  Future<int> minFeeRate() async {
    return 1000;
  }
}
