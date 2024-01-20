import 'package:aqua/wallet.dart';
import 'package:aqua/data/models/gdk_models.dart';

class BitcoinNetwork extends WalletService {
  BitcoinNetwork() : super() {
    networkName = 'Bitcoin';
  }

  @override
  Future<bool> connect({
    GdkConnectionParams connectionParams = const GdkConnectionParams(
      name: 'electrum-testnet',
    ),
  }) async {
    return super.connect(connectionParams: connectionParams);
  }
}
