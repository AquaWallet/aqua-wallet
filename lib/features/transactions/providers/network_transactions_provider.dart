import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/models/transaction_lookup_model.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:rxdart/rxdart.dart';

final networkTransactionsProvider =
    StreamProvider.family<List<GdkTransaction>, Asset>((ref, asset) async* {
  ref.watch(storedWalletsProvider.select((s) => s.valueOrNull?.currentWallet));

  final networkProvider = asset.isBTC ? bitcoinProvider : liquidProvider;
  final network = ref.watch(networkProvider);

  // Refresh transaction list on both transaction events AND block events.
  // Block events update transaction blockHeight (confirmations) which is
  // needed to transition pending transactions to confirmed state.
  final transactionStream = Rx.merge([
    network.transactionEventSubject.cast<void>(),
    network.blockHeightEventSubject.cast<void>(),
  ])
      .startWith(null)
      .asyncMap((_) =>
          ref.read(networkProvider).getTransactions(requiresRefresh: true))
      .map((transactions) => transactions ?? []);

  if (!asset.isBTC) {
    yield* transactionStream.map((transactions) => transactions
        .where((transaction) => transaction.satoshi?[asset.id] != null)
        .toList());
  }

  yield* transactionStream;
});

final networkTransactionsLookupProvider =
    FutureProvider<Map<String, TransactionLookupModel>>((ref) async {
  final networkTransactions = {};
  final assets = await ref.watch(assetsProvider.future);
  for (final asset in assets) {
    final assetTransactions =
        await ref.watch(networkTransactionsProvider(asset).future);
    networkTransactions[asset.id] = assetTransactions;
  }

  final Map<String, TransactionLookupModel> result = {};

  for (var assetId in networkTransactions.keys) {
    final List<GdkTransaction> assetTransactions = networkTransactions[assetId];
    for (var transaction in assetTransactions) {
      result[transaction.txhash] =
          TransactionLookupModel(assetId: assetId, gdkTransaction: transaction);
    }
  }

  return result;
});
