// Mock assets based on the provided JSON
import 'package:aqua/features/settings/manage_assets/models/assets.dart';

final lbtcAsset = Asset(
  id: '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d',
  name: 'Liquid Bitcoin',
  ticker: 'L-BTC',
  logoUrl: 'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/L-BTC.svg',
  isDefaultAsset: true,
  isRemovable: false,
  isLBTC: true,
  isLiquid: true,
);

final usdtAsset = Asset(
  id: 'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2',
  name: 'Tether USDt',
  ticker: 'USDt',
  logoUrl: 'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/USDt.svg',
  isDefaultAsset: true,
  isRemovable: true,
  isUSDt: true,
  isLiquid: true,
);

final infAsset = Asset(
  id: '20f235a1096c05a5d9b1d40d09112d3d57eb3a7ac9959beebf0ae5f774a7fd68',
  name: 'INF',
  ticker: 'INF',
  logoUrl: 'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/INF.svg',
  isDefaultAsset: false,
  isRemovable: true,
  precision: 2,
  isLiquid: true,
);

final jpysAsset = Asset(
  id: '3438ecb49fc45c08e687de4749ed628c511e326460ea4336794e1cf02741329e',
  name: 'JPY Stablecoin',
  ticker: 'JPYS',
  logoUrl: 'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/JPYS.svg',
  isDefaultAsset: false,
  isRemovable: true,
  isLiquid: true,
);

final eurxAsset = Asset(
  id: '18729918ab4bca843656f08d4dd877bed6641fbd596a0a963abbf199cfeb3cec',
  name: 'PEGx EURx',
  ticker: 'EURx',
  logoUrl: 'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/EURx.svg',
  isDefaultAsset: false,
  isRemovable: true,
  isLiquid: true,
);

final mexAsset = Asset(
  id: '26ac924263ba547b706251635550a8649545ee5c074fe5db8d7140557baaf32e',
  name: 'Mexas',
  ticker: 'MEX',
  logoUrl: 'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/MEX.svg',
  isDefaultAsset: false,
  isRemovable: true,
  isLiquid: true,
);

final depixAsset = Asset(
  id: '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189',
  name: 'DePix',
  ticker: 'DePix',
  logoUrl: 'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/DePix.svg',
  isDefaultAsset: false,
  isRemovable: true,
  isLiquid: true,
);

final btcAsset = Asset(
  id: 'btc',
  name: 'Bitcoin',
  ticker: 'BTC',
  logoUrl: '',
  isDefaultAsset: true,
);
