import 'dart:async';
import 'dart:io';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/settings/electrum_server/providers/electrum_server_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:lwk/lwk.dart' as lwk;
import 'package:path_provider/path_provider.dart';

/// LWK-based implementation of NetworkFrontend for Liquid network operations
class LwkNetworkFrontend {
  LwkNetworkFrontend({required this.ref});
  final ProviderRef ref;
  String internalMnemonic = '';
  late lwk.Network network;
  lwk.Descriptor? _descriptor;

  // LWK-specific state
  lwk.Wallet? _wollet;

  Future<bool> init() async {
    try {
      logger.debug('[LWK] Initializing LWK NetworkFrontend');

      await lwk.LibLwk.init();

      logger.debug('[LWK] LWK NetworkFrontend initialized successfully');
      return true;
    } catch (e) {
      logger.error('[LWK] Failed to initialize LWK: $e');
      return false;
    }
  }

  Future<bool> verifyInitialized() async {
    if (_wollet != null) {
      return true;
    }
    return await _login();
  }

  Future<void> syncWallet() async {
    if (_wollet == null) {
      throw Exception('LWK wallet not logged in');
    }
    final networkType = switch (network) {
      lwk.Network.mainnet => NetworkType.liquid,
      lwk.Network.testnet => NetworkType.liquidTestnet,
    };
    try {
      final electrumUrl =
          ref.read(electrumServerProvider).getElectrumUrl(networkType);
      await _wollet!.sync_(electrumUrl: electrumUrl, validateDomain: true);
    } catch (e) {
      logger.error('[LWK] Failed to sync wallet: $e');
      rethrow;
    }
  }

  Future<Directory> _getLwkDatabaseDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final lwkDir = Directory('${appDir.path}/lwk');
    return lwkDir;
  }

  Future<bool> _login({bool isRetry = false}) async {
    if (_descriptor == null || internalMnemonic.isEmpty) {
      return false;
    }
    try {
      final lwkDir = await _getLwkDatabaseDirectory();

      final w = await lwk.Wallet.init(
        network: network,
        dbpath: lwkDir.path,
        descriptor: _descriptor!,
      );
      _wollet = w;
      return true;
    } catch (e) {
      if (e is lwk.LwkError) {
        logger.error('[LWK] Login failed with LWK error: ${e.msg}');

        // If UpdateOnDifferentStatus error and not already a retry, delete db and retry
        if (e.msg.contains('UpdateOnDifferentStatus') && !isRetry) {
          logger.debug(
              '[LWK] Detected UpdateOnDifferentStatus, deleting LWK database and retrying');
          await _deleteLwkDatabase();
          return _login(isRetry: true);
        }
        return false;
      }
      logger.error('[LWK] Login failed: $e');
      return false;
    }
  }

  Future<void> _deleteLwkDatabase() async {
    try {
      final lwkDir = await _getLwkDatabaseDirectory();
      if (await lwkDir.exists()) {
        logger.debug('[LWK] Deleting LWK database directory: ${lwkDir.path}');
        await lwkDir.delete(recursive: true);
      }
      logger.debug('[LWK] LWK database deleted successfully');
    } catch (e) {
      logger.error('[LWK] Failed to delete LWK database: $e');
    }
  }

  Future<bool> loginUser(
      {required GdkLoginCredentials credentials,
      required liquidCtDescriptor}) async {
    internalMnemonic = credentials.mnemonic;
    network = ref.read(envProvider) == Env.mainnet
        ? lwk.Network.mainnet
        : lwk.Network.testnet;

    _descriptor = lwk.Descriptor(
      ctDescriptor: liquidCtDescriptor,
    );
    return await _login();
  }

  Future<lwk.PayjoinTx> createPayjoin({
    required int usdtSats,
    required String outAddress,
    required String asset,
    String? baseUrl,
  }) async {
    if (_wollet == null) {
      throw Exception('LWK wallet not logged in');
    }
    return _wollet!.buildPayjoinTx(
        sats: BigInt.from(usdtSats),
        outAddress: outAddress,
        asset: asset,
        network: network,
        baseUrl: baseUrl);
  }

  Future<String> signPsetWithExtraDetails(String pset) async {
    if (_wollet == null || internalMnemonic.isEmpty) {
      throw Exception(
          'LWK wallet not logged in or mnemonic not set for signing');
    }
    return _wollet!.signedPsetWithExtraDetails(
        pset: pset, network: network, mnemonic: internalMnemonic);
  }

  Future<void> disconnect() async {
    _wollet = null;
    network = lwk.Network.mainnet;
    internalMnemonic = '';
  }

  Future<List<lwk.Balance>> getBalances() async {
    if (_wollet == null) {
      throw Exception('LWK wallet not logged in');
    }
    return _wollet!.balances();
  }
}

final lwkProvider =
    Provider<LwkNetworkFrontend>((ref) => LwkNetworkFrontend(ref: ref));
