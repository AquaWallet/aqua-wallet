import 'package:collection/collection.dart';
import 'package:aqua/features/depix/models/models.dart';
import 'package:aqua/features/depix/providers/depix_deposit_provider.dart';
import 'package:aqua/features/depix/providers/depix_flow_provider.dart';
import 'package:aqua/features/depix/services/jan3_api_depix.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DepixDepositsListNotifier
    extends AutoDisposeAsyncNotifier<EulenDepositsResponse?> {
  @override
  Future<EulenDepositsResponse?> build() => _fetchDeposits();

  Future<EulenDepositsResponse?> refreshDeposits() async {
    state = await AsyncValue.guard(_fetchDeposits);
    return state.valueOrNull;
  }

  Future<void> onCtaPressed() async {
    final hasPending =
        state.valueOrNull?.deposits.any((d) => d.status.isPending) ?? false;
    if (!hasPending) {
      ref.read(depixFlowProvider.notifier).setStep(DepixStep.amountEntry);
      return;
    }
    await refreshDeposits();
    if (state.hasError) return;
    final pending =
        state.valueOrNull?.deposits.firstWhereOrNull((d) => d.status.isPending);
    if (pending == null) {
      ref.read(depixFlowProvider.notifier).setStep(DepixStep.amountEntry);
      return;
    }
    if (pending.qrCopyPaste == null) {
      ref.read(depixFlowProvider.notifier).setStep(DepixStep.amountEntry);
      return;
    }
    ref.read(depixDepositProvider.notifier).resumePendingDeposit(pending);
    ref.read(depixFlowProvider.notifier).setStep(DepixStep.depositQr);
  }

  Future<EulenDepositsResponse?> _fetchDeposits() async {
    final api = ref.read(jan3ApiDepixProvider);
    final response = await api.getDeposits();
    // Eulen profile is not set up on the first time the user sees the deposits list. This is expected
    if (response.statusCode == 404) {
      return const EulenDepositsResponse(deposits: [], count: 0);
    }
    if (!response.isSuccessful || response.body == null) {
      throw DepixDepositRequestFailedError(
        statusCode: response.statusCode,
        responseError: response.error,
      );
    }
    return response.body;
  }
}

final depixDepositsListProvider = AutoDisposeAsyncNotifierProvider<
    DepixDepositsListNotifier, EulenDepositsResponse?>(
  DepixDepositsListNotifier.new,
);
