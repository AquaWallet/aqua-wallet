import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/rbf/rbf.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';

final bitcoinRbfInputStateProvider = AutoDisposeAsyncNotifierProviderFamily<
    _BitcoinRbfNotifier, RbfInputState, String>(_BitcoinRbfNotifier.new);

class _BitcoinRbfNotifier
    extends AutoDisposeFamilyAsyncNotifier<RbfInputState, String> {
  final _asset = Asset.btc();

  @override
  FutureOr<RbfInputState> build(String arg) async {
    final txnId = arg;
    final txns = await ref.watch(networkTransactionsProvider(_asset).future);
    final txn = txns.firstWhereOrNull((t) => t.txhash == txnId);

    if (txn == null) {
      throw RbfTransactionNotFoundException();
    }

    final txnVsize = txn.transactionVsize;
    if (txnVsize == null) {
      throw RbfTransactionVsizeNotFoundException();
    }

    final feeRate = txn.feeRate;
    if (feeRate == null) {
      throw RbfFeeRateNotFoundException();
    }

    final minFeeRate = (feeRate ~/ kVbPerKb) + 1;
    final feeAmount = minFeeRate * txnVsize;
    final feeInFiat =
        await ref.read(satsToFiatDisplayWithSymbolProvider(feeAmount).future);

    return RbfInputState(
      transaction: txn,
      transactionVsize: txnVsize,
      feeRate: feeRate,
      minFeeRate: minFeeRate,
      feeAmount: feeAmount,
      feeInFiat: feeInFiat,
    );
  }

  Future<void> updateFeeRate(String text) async {
    final prevState = state.value;
    if (prevState == null) {
      return;
    }

    state = await AsyncValue.guard(() async {
      final txnVsize = prevState.transactionVsize;
      final minFeeRate = prevState.minFeeRate;
      final customRateSatsPerVByte = int.tryParse(text) ?? 0;
      final feeAmount = customRateSatsPerVByte * txnVsize;
      final isBelowMinimum =
          text.isNotEmpty && minFeeRate > customRateSatsPerVByte;

      if (isBelowMinimum) {
        throw RbfAmountBelowMinimum(minFeeRate: minFeeRate);
      }

      final feeInFiat =
          await ref.read(satsToFiatDisplayWithSymbolProvider(feeAmount).future);

      return prevState.copyWith(
        feeRate: customRateSatsPerVByte,
        feeAmount: feeAmount,
        feeInFiat: feeInFiat,
      );
    });
  }
}
