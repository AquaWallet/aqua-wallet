import 'package:aqua/wallet.dart';
import 'package:aqua/data/models/gdk_models.dart';

class BitcoinNetwork extends WalletService {
  BitcoinNetwork() : super() {
    networkName = 'Bitcoin';
  }

  @override
  Future<bool> connect({
    GdkConnectionParams? connectionParams,
  }) async {
    final params = connectionParams ??
        const GdkConnectionParams(
          name: 'electrum-bitcoin',
        );

    final result = await super.connect(connectionParams: params);
    return result;
  }
}
