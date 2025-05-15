// NOTE: Copied from lib/features/settings/manage_assets/models/assets.dart

class AssetIds {
  static const btc = 'btc';
  static const lightning = 'lightning';
  static const usdtEth = 'eth-usdt';
  static const usdtTrx = 'trx-usdt';
  static const usdtBep = 'bep-usdt';
  static const usdtSol = 'sol-usdt';
  static const usdtPol = 'pol-usdt';
  static const usdtTon = 'ton-usdt';
  static const usdtliquid = [
    'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2',
    'b612eb46313a2cd6ebabd8b7a8eed5696e29898b87a43bff41c94f51acef9d73',
    'a0682b2b1493596f93cea5f4582df6a900b5e1a491d5ac39dea4bb39d0a45bbf',
  ];
  static const lbtc = [
    '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d',
    '144c654344aa716d6f3abcc1ca90e5641e4e2a7f633bc09fe3baf64585819a49',
  ];
  static const mexas = [
    '26ac924263ba547b706251635550a8649545ee5c074fe5db8d7140557baaf32e',
    '485ff8a902ad063bd8886ef8cfc0d22a068d14dcbe6ae06cf3f904dc581fbd2b',
  ];
  static const depix =
      '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189';
  static const eurx = [
    '18729918ab4bca843656f08d4dd877bed6641fbd596a0a963abbf199cfeb3cec',
    '58af36e1b529b42f3e4ccce812924380058cae18b2ad26c89805813a9db25980',
  ];

  //NOTE - Mock IDs to simulate asset icons
  static const layer2 = 'layer2';
  static const usdtTether = 'usdt-tether';

  static bool isAnyUsdt(String assetId) =>
      usdtliquid.contains(assetId) ||
      usdtTether == assetId ||
      usdtEth == assetId ||
      usdtTrx == assetId ||
      usdtBep == assetId ||
      usdtSol == assetId ||
      usdtTon == assetId ||
      usdtPol == assetId;
}
