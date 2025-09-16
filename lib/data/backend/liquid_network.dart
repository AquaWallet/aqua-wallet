import 'package:coin_cz/wallet.dart';
import 'package:coin_cz/data/models/gdk_models.dart';

class LiquidNetwork extends WalletService {
  LiquidNetwork() : super() {
    networkName = 'Liquid';
  }

  @override
  Future<bool> connect({
    GdkConnectionParams connectionParams = const GdkConnectionParams(
      name: 'electrum-testnet-liquid',
    ),
  }) async {
    return await super.connect(connectionParams: connectionParams);
  }
}
