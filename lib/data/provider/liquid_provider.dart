import 'package:aqua/data/backend/liquid_network.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

enum LiquidNetworkEnumType {
  regtest,
  testnet,
  mainnet,
}

class LiquidNetworkFactory {
  final GdkRegisterNetworkData? networkData;
  final GdkConnectionParams params;
  final String networkName;
  final LiquidNetworkEnumType networkType;

  LiquidNetworkFactory(
    this.networkData,
    this.params,
    this.networkName,
    this.networkType,
  );

  factory LiquidNetworkFactory.fromEnv(Env envType) {
    GdkConnectionParams params;
    GdkRegisterNetworkData? networkData;
    String networkName;
    LiquidNetworkEnumType networkType;

    switch (envType) {
      case Env.regtest:
        networkName = 'electrum-sideswap-regtest';
        networkType = LiquidNetworkEnumType.regtest;
        networkData = GdkRegisterNetworkData(
          name: networkName,
          networkDetails: const GdkNetwork(
            addressExplorerUrl:
                'https://blockstream.info/liquidtestnet/address/',
            assetRegistryOnionUrl: '',
            assetRegistryUrl: 'https://staging.sideswap.io/assets',
            bech32Prefix: 'ert',
            bip21Prefix: 'liquidtestnet',
            blech32Prefix: 'el',
            blindedPrefix: 4,
            csvBuckets: [],
            ctBits: 52,
            ctExponent: 0,
            development: false,
            electrumTls: false,
            electrumUrl: 'api.sideswap.io:10402',
            liquid: true,
            mainnet: false,
            name: 'Testnet Liquid (Electrum)',
            network: 'electrum-testnet-liquid',
            p2PkhVersion: 57,
            p2ShVersion: 39,
            policyAsset:
                '2e16b12daf1244332a438e829ca7ce209195f8e1c54199770cd8b327710a8ab2',
            serverType: ServerTypeEnum.electrum,
            serviceChainCode: '',
            servicePubkey: '',
            spvMulti: false,
            spvServers: <dynamic>[],
            spvEnabled: false,
            txExplorerUrl: 'https://blockstream.info/liquidtestnet/tx/',
            wampCertPins: [],
            wampCertRoots: [],
            wampOnionUrl: '',
            wampUrl: '',
          ),
        );

        params = GdkConnectionParams(
          name: networkName,
          minFeeRate: 10,
        );
        break;
      case Env.testnet:
        networkName = 'electrum-testnet-liquid';
        networkType = LiquidNetworkEnumType.testnet;
        params = GdkConnectionParams(
          name: networkName,
          minFeeRate: 10,
        );
        break;
      case Env.mainnet:
        networkName = 'electrum-liquid';
        networkType = LiquidNetworkEnumType.mainnet;
        params = GdkConnectionParams(name: networkName);
        networkName = 'electrum-liquid';
        networkType = LiquidNetworkEnumType.mainnet;
        params = GdkConnectionParams(
          name: networkName,
          minFeeRate: 10,
        );
        break;
    }
    logger.i("[ENV] $envType - using liquid network: $networkName");
    return LiquidNetworkFactory(networkData, params, networkName, networkType);
  }
}

final liquidProvider = Provider<LiquidProvider>((ref) => LiquidProvider(
      ref: ref,
      session: LiquidNetwork(),
    ));

class LiquidProvider extends NetworkFrontend {
  LiquidNetworkFactory? liquidNetworkFactory;

  LiquidProvider({required super.ref, required super.session}) {
    addEventListener(listener: onGdkEvent);
  }

  Future<void> onGdkEvent(dynamic value) async {
    switch (value.runtimeType.toString()) {
      case '_\$_GdkNetworkEvent':
        final result = value as GdkNetworkEvent;

        if (isLogged &&
            result.currentState == GdkNetworkEventStateEnum.connected) {
          await refreshAssets(requiresRefresh: true);
        }
        break;
    }
  }

  @override
  Future<bool> connect({
    GdkConnectionParams? params,
  }) async {
    final env = ref.read(envProvider);
    liquidNetworkFactory = LiquidNetworkFactory.fromEnv(env);

    if (liquidNetworkFactory?.networkData != null) {
      final networkRegistered =
          await super.registerNetwork(liquidNetworkFactory!.networkData!);

      if (!networkRegistered) {
        logger.e(
            '[$runtimeType] Registering network ${liquidNetworkFactory?.networkName} failed!');
        return false;
      }
    }

    if (liquidNetworkFactory?.params != null) {
      return super.connect(params: liquidNetworkFactory!.params);
    }

    logger.e(
        '[$runtimeType] Unable connect to network: ${liquidNetworkFactory?.networkName}');
    return false;
  }

  Future<void> onBackendError(dynamic error) async {
    logger.e('[$runtimeType] Liquid provider error: $error');
  }

  @override
  Future<bool> init() async {
    logger.d('[$runtimeType] Initializing liquid backend');
    final result = await super.init();

    if (!result) {
      throw InitializeNetworkFrontendException();
    }

    logger.d('[$runtimeType] Liquid backend initialized: $result');

    return result;
  }

  String get usdtId {
    return switch (liquidNetworkFactory?.networkType) {
      LiquidNetworkEnumType.mainnet =>
        'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2',
      LiquidNetworkEnumType.testnet =>
        'b612eb46313a2cd6ebabd8b7a8eed5696e29898b87a43bff41c94f51acef9d73',
      _ => 'a0682b2b1493596f93cea5f4582df6a900b5e1a491d5ac39dea4bb39d0a45bbf',
    };
  }

  String get lbtcId {
    return switch (liquidNetworkFactory?.networkType) {
      LiquidNetworkEnumType.mainnet =>
        '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d',
      _ => '144c654344aa716d6f3abcc1ca90e5641e4e2a7f633bc09fe3baf64585819a49'
    };
  }

  String get mexasId {
    return switch (liquidNetworkFactory?.networkType) {
      LiquidNetworkEnumType.mainnet =>
        '26ac924263ba547b706251635550a8649545ee5c074fe5db8d7140557baaf32e',
      _ => '485ff8a902ad063bd8886ef8cfc0d22a068d14dcbe6ae06cf3f904dc581fbd2b'
    };
  }

  String get depixId {
    return switch (liquidNetworkFactory?.networkType) {
      LiquidNetworkEnumType.mainnet =>
        '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189',
      _ => '' // testnet currently not available
    };
  }

  String get eurXId {
    return switch (liquidNetworkFactory?.networkType) {
      LiquidNetworkEnumType.mainnet =>
        '18729918ab4bca843656f08d4dd877bed6641fbd596a0a963abbf199cfeb3cec',
      _ => '58af36e1b529b42f3e4ccce812924380058cae18b2ad26c89805813a9db25980'
    };
  }

  @override
  Future<int> minFeeRate() async {
    return 100;
  }
}
