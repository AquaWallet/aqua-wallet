import 'dart:async';

import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/shared/shared.dart';

final bitcoinRbfProvider = AutoDisposeAsyncNotifierProviderFamily<
    _BitcoinRbfNotifier, String?, GdkTransaction>(_BitcoinRbfNotifier.new);

class _BitcoinRbfNotifier
    extends AutoDisposeFamilyAsyncNotifier<String?, GdkTransaction> {
  @override
  FutureOr<String?> build(GdkTransaction arg) => null;

  void createRbfTransaction(double rate) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final newFeeRatePerVb = DecimalExt.fromDouble(rate).toBigInt().toInt();
      final tx = GdkNewTransaction(
        previousTransaction: arg,
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

      final id = await ref
          .read(electrsProvider)
          .broadcast(signedTx.transaction!, NetworkType.bitcoin);

      return id;
    });
  }
}
