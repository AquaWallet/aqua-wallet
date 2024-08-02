import 'package:aqua/wallet.dart';
import 'package:aqua/data/models/gdk_models.dart';

class LiquidNetwork extends WalletService {
  LiquidNetwork() : super() {
    networkName = 'Liquid';
  }

  @override
  Future<bool> connect({
    GdkConnectionParams connectionParams = const GdkConnectionParams(
      name: 'electrum-testnet-liquid',
      minFeeRate: 10,
    ),
  }) async {
    return super.connect(connectionParams: connectionParams);
  }
}
