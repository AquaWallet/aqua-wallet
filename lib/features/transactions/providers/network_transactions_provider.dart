import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/settings/manage_assets/models/assets.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:rxdart/rxdart.dart';

final networkTransactionsProvider =
    StreamProvider.family<List<GdkTransaction>, Asset>((ref, asset) async* {
  final networkProvider = asset.isBTC ? bitcoinProvider : liquidProvider;
  final networkTxs = ref
      .read(networkProvider)
      .transactionEventSubject
      .startWith(null)
      .asyncMap((_) =>
          ref.read(networkProvider).getTransactions(requiresRefresh: true))
      .map((transactions) => transactions ?? []);

  if (!asset.isBTC) {
    yield* networkTxs.map((transactions) => transactions
        .where((transaction) => transaction.satoshi?[asset.id] != null)
        .toList());
  }

  yield* networkTxs;
});
