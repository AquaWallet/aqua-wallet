//NOTE - Mock data for testing and skeleton loading

import 'package:aqua/features/settings/settings.dart';

List<Asset> get mockAssetsList => [
      Asset(
        id: 'btc',
        name: 'Bitcoin',
        ticker: 'BTC',
        amount: 1000,
        logoUrl: '',
        isUSDt: false,
        isLBTC: false,
      ),
      Asset(
        id: 'lbtc',
        name: 'Liquid Bitcoin',
        ticker: 'L-BTC',
        amount: 1000,
        logoUrl: '',
        isUSDt: false,
        isLBTC: true,
      ),
      Asset(
        id: 'usdt',
        name: 'Tether USD',
        ticker: 'USDt',
        amount: 1000,
        logoUrl: '',
        isUSDt: true,
        isLBTC: false,
      ),
    ];
