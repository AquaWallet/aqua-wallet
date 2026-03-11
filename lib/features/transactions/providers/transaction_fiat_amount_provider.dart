import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:rxdart/rxdart.dart';

final _rateStreamProvider = StreamProvider.autoDispose((ref) async* {
  yield* ref.read(fiatProvider).rateStream.distinctUnique();
});

final fiatAmountProvider = FutureProvider.autoDispose
    .family<String, TransactionUiModel>((ref, model) async {
  final rate = ref.watch(_rateStreamProvider).asData?.value;

  final fiats = ref.read(fiatProvider);
  if (rate != null) {
    final (amount, assetForFiat) = model.map(
      normal: (model) {
        final effectiveAsset = model.fiatAsset ?? model.asset;
        return (
          model.transaction.satoshi?[effectiveAsset.id] ?? 0,
          effectiveAsset,
        );
      },
      pending: (model) => (model.dbTransaction!.ghostTxnAmount!, model.asset),
    );
    final fiat = fiats.satoshiToFiat(assetForFiat, amount, rate.$1);
    final formattedFiat = fiats.formatFiat(fiat, rate.$2);

    final dbTxn = model.dbTransaction;
    final isUsdtSwap = model.involvesUsdt;
    final shouldShowFiatAmount = (dbTxn?.isAnySwap ?? false) && !isUsdtSwap;

    // For pending swaps: only show fiat if it's not a sideswap swap and shouldShowFiatAmount is true
    if (model.isPending && dbTxn != null) {
      if (dbTxn.isAnySwap && !dbTxn.isUSDtSwap) {
        return !dbTxn.isSwap && shouldShowFiatAmount ? formattedFiat : '';
      }
    }

    return formattedFiat;
  } else {
    return '';
  }
});
