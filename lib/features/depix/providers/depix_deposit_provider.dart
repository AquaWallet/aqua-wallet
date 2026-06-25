import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/depix/models/models.dart';
import 'package:aqua/features/depix/providers/depix_flow_provider.dart';
import 'package:aqua/features/depix/services/jan3_api_depix.dart';
import 'package:aqua/features/shared/pages/amount_entry/amount_entry_spec.dart';
import 'package:decimal/decimal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef DepixDepositResult = ({
  EulenDepositResponse deposit,
  int amountBrlCents
});

class DepixDepositNotifier
    extends AutoDisposeAsyncNotifier<DepixDepositResult?> {
  @override
  DepixDepositResult? build() => null;

  Future<void> submit(int amountBrlCents) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final address = await ref.read(liquidProvider).getReceiveAddress();
      final liquidAddress = address?.address;
      if (liquidAddress == null) throw DepixLiquidAddressNotFoundError();

      final api = ref.read(jan3ApiDepixProvider);
      final response = await api.deposit(
        EulenDepositRequest(
          amountBrlCents: amountBrlCents,
          liquidDepixAddress: liquidAddress,
        ),
      );
      if (!response.isSuccessful || response.body == null) {
        throw DepixDepositRequestFailedError(
          statusCode: response.statusCode,
          responseError: response.error,
        );
      }
      return (deposit: response.body!, amountBrlCents: amountBrlCents);
    });
  }

  Future<void> submitFromAmountEntry(
    double amount,
    bool isReversed,
    AmountEntrySpec spec,
  ) async {
    final amountBrlCents = isReversed
        ? (amountEntryAssetToFiatAmount(Decimal.parse(amount.toString()), spec)
                    .toDouble() *
                100)
            .round()
        : (amount * 100).round();
    await submit(amountBrlCents);
    ref.read(depixFlowProvider.notifier).setStep(DepixStep.depositQr);
  }

  void resumePendingDeposit(EulenDeposit pendingDeposit) {
    final qrCopyPaste = pendingDeposit.qrCopyPaste;
    if (qrCopyPaste == null) {
      state = AsyncError(
        DepixPendingDepositMissingPayloadError(),
        StackTrace.current,
      );
      return;
    }

    state = AsyncData((
      deposit: EulenDepositResponse(
        qrCopyPaste: qrCopyPaste,
        qrImageUrl: pendingDeposit.qrImageUrl ?? '',
        depositId: pendingDeposit.depositId,
      ),
      amountBrlCents: pendingDeposit.amountBrlCents,
    ));
  }
}

final depixDepositProvider =
    AutoDisposeAsyncNotifierProvider<DepixDepositNotifier, DepixDepositResult?>(
  DepixDepositNotifier.new,
);
