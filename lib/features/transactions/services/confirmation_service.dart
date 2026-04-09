import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/providers/peg_storage_provider.dart';
import 'package:aqua/features/transactions/providers/network_transactions_provider.dart';
import 'package:aqua/features/transactions/providers/peg_swap_matcher_provider.dart';

final confirmationServiceProvider = Provider.autoDispose((ref) {
  return ConfirmationService(
    aquaProvider: ref.read(aquaProvider),
    pegStorage: ref.read(pegStorageProvider.notifier),
    pegSwapMatcher: ref.read(pegSwapMatcherProvider),
    getNetworkTransactions: (asset) =>
        ref.read(networkTransactionsProvider(asset).future),
  );
});

// Handles confirmation count logic and pending state determination
//
// This service centralizes all logic related to transaction confirmations
// and determining whether a transaction should be considered pending.
class ConfirmationService {
  const ConfirmationService({
    required this.aquaProvider,
    required this.pegStorage,
    required this.pegSwapMatcher,
    required this.getNetworkTransactions,
  });

  final AquaProvider aquaProvider;
  final PegOrderStorageNotifier pegStorage;
  final PegSwapMatcher pegSwapMatcher;
  final Future<List<GdkTransaction>> Function(Asset asset)
      getNetworkTransactions;

  Future<int> getConfirmationCount(Asset asset, int blockHeight) => aquaProvider
      .getConfirmationCount(
        asset: asset,
        transactionBlockHeight: blockHeight,
      )
      .first;

  int getRequiredConfirmationCount(Asset asset) {
    return asset.isBTC
        ? onchainConfirmationBlockCount
        : liquidConfirmationBlockCount;
  }

  // Determines if a transaction is still pending based on confirmation count.
  // For peg transactions, pass the dbTransaction so both sides are checked.
  Future<bool> isTransactionPending({
    required GdkTransaction transaction,
    required Asset asset,
    TransactionDbModel? dbTransaction,
  }) async {
    if (dbTransaction != null && dbTransaction.isPeg) {
      return _isPegTransactionPending(
        transaction: transaction,
        dbTransaction: dbTransaction,
      );
    }

    final confirmationCount = await getConfirmationCount(
      asset,
      transaction.blockHeight ?? 0,
    );
    return confirmationCount < getRequiredConfirmationCount(asset);
  }

  Future<bool> _isPegTransactionPending({
    required GdkTransaction transaction,
    required TransactionDbModel dbTransaction,
  }) async {
    final isPegIn = dbTransaction.isPegIn;
    final sendAsset = isPegIn ? Asset.btc() : Asset.lbtc();
    final receiveAsset = isPegIn ? Asset.lbtc() : Asset.btc();

    final sendNetworkTxns = await getNetworkTransactions(sendAsset);
    final receiveNetworkTxns = await getNetworkTransactions(receiveAsset);

    final (:sendTxn, :receiveTxn) = pegSwapMatcher.lookupPegSides(
      pegOrder: dbTransaction,
      sendNetworkTxns: sendNetworkTxns,
      receiveNetworkTxns: receiveNetworkTxns,
    );

    if (sendTxn == null) {
      if (sendNetworkTxns.isEmpty) {
        return false;
      }
      return !_shouldIgnoreGhost(
        ghostTxnCreatedAtMicroseconds:
            dbTransaction.ghostTxnCreatedAt?.microsecondsSinceEpoch,
        lastNetworkTxn: sendNetworkTxns.last,
      );
    }

    final isSendSidePending = await isTransactionPending(
      transaction: sendTxn,
      asset: sendAsset,
    );

// If the receive transaction is not found, check if the ghost transaction is older than the last network transaction
    if (receiveTxn == null) {
      if (receiveNetworkTxns.isEmpty) {
        return false;
      }
      final sendCreatedAtTs = sendTxn.createdAtTs;
      return !_shouldIgnoreGhost(
        ghostTxnCreatedAtMicroseconds: sendCreatedAtTs,
        lastNetworkTxn: sendNetworkTxns.last,
      );
    }

    final receiveConfirmations = await getConfirmationCount(
      receiveAsset,
      receiveTxn.blockHeight ?? 0,
    );
    final isReceiveSidePending =
        receiveConfirmations < getRequiredConfirmationCount(receiveAsset);

    return isSendSidePending || isReceiveSidePending;
  }

  // Determines if a ghost/boltz transaction is still pending by checking
  // staleness against network transactions and confirmation count.
  Future<bool> isGhostTransactionPending({
    required TransactionDbModel ghostTxn,
    required Asset asset,
    required List<GdkTransaction> networkTxns,
  }) async {
    final matchingNetworkTxn =
        networkTxns.firstWhereOrNull((t) => t.txhash == ghostTxn.txhash);

    if (matchingNetworkTxn == null && networkTxns.isNotEmpty) {
      if (_shouldIgnoreGhost(
        ghostTxnCreatedAtMicroseconds:
            ghostTxn.ghostTxnCreatedAt?.microsecondsSinceEpoch,
        lastNetworkTxn: networkTxns.last,
      )) {
        return false;
      }
    }

    final confirmationCount = await getConfirmationCount(
      asset,
      matchingNetworkTxn?.blockHeight ?? 0,
    );
    return confirmationCount < getRequiredConfirmationCount(asset);
  }

  bool _shouldIgnoreGhost({
    required int? ghostTxnCreatedAtMicroseconds,
    required GdkTransaction lastNetworkTxn,
  }) {
    if (lastNetworkTxn.createdAtTs == null ||
        ghostTxnCreatedAtMicroseconds == null) {
      return true;
    }
    return (ghostTxnCreatedAtMicroseconds < lastNetworkTxn.createdAtTs!);
  }
}
