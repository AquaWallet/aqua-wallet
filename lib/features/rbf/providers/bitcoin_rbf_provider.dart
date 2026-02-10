import 'dart:async';

import 'package:aqua/common/common.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/rbf/rbf.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';

final bitcoinRbfProvider = AutoDisposeAsyncNotifierProviderFamily<
    _BitcoinRbfNotifier, String?, String>(_BitcoinRbfNotifier.new);

class _BitcoinRbfNotifier
    extends AutoDisposeFamilyAsyncNotifier<String?, String> {
  final _asset = Asset.btc();

  @override
  FutureOr<String?> build(String arg) => null;

  void createRbfTransaction(double rate) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final transactionId = arg;

      final txns = await ref.watch(networkTransactionsProvider(_asset).future);
      final txn = txns.firstWhereOrNull((t) => t.txhash == transactionId);

      if (txn == null) {
        throw RbfTransactionNotFoundException();
      }

      final newFeeRatePerVb = DecimalExt.fromDouble(rate).toBigInt().toInt();
      final tx = GdkNewTransaction(
        previousTransaction: txn,
        feeRate: (newFeeRatePerVb * kVbPerKb).toInt(),
      );

      final txReply = await ref
          .read(bitcoinProvider)
          .createTransaction(transaction: tx, isRbfTx: true);

      if (txReply == null) {
        throw GdkNetworkException('Failed to create GDK transaction');
      }

      final signedTx = await ref.read(bitcoinProvider).signTransaction(txReply);
      if (signedTx == null) {
        throw GdkNetworkException('Failed to sign GDK transaction');
      }

      final newTxId = await ref
          .read(electrsProvider)
          .broadcast(signedTx.transaction!, NetworkType.bitcoin);

      await _updateDatabaseForRbf(transactionId, newTxId);

      ref.invalidate(transactionsProvider(_asset));

      return newTxId;
    });
  }

  Future<void> _updateDatabaseForRbf(
    String originalTxHash,
    String newTxHash,
  ) async {
    final dbTxns = ref.read(transactionStorageProvider).valueOrNull ?? [];
    final dbTxn = dbTxns.firstWhereOrNull((t) => t.txhash == originalTxHash);

    if (dbTxn != null) {
      // Update the transaction hash to the new RBF transaction
      final updatedTxn = dbTxn.copyWith(txhash: newTxHash);
      await ref.read(transactionStorageProvider.notifier).save(updatedTxn);
    }
  }
}
