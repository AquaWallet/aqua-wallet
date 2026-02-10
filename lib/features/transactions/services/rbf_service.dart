import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

final rbfServiceProvider = Provider<RbfService>((ref) {
  return RbfService(
    bitcoinProvider: ref.read(bitcoinProvider),
    liquidProvider: ref.read(liquidProvider),
  );
});

// Service for handling Replace-By-Fee (RBF) operations
//TODO - Move the business logic from RBF provider here
class RbfService {
  const RbfService({
    required this.bitcoinProvider,
    required this.liquidProvider,
  });

  final BitcoinProvider bitcoinProvider;
  final LiquidProvider liquidProvider;

  Future<bool> isRbfAllowed({
    required Asset asset,
    required String txHash,
  }) async {
    final network = asset.isBTC ? bitcoinProvider : liquidProvider;
    final allTxns = await network.getTransactions(requiresRefresh: true) ?? [];
    final txn = allTxns.firstWhereOrNull((t) => t.txhash == txHash);
    return txn?.canRbf ?? false;
  }
}
