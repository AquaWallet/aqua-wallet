import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/lending/models/models.dart';
import 'package:aqua/features/lending/providers/lending_provider.dart';
import 'package:aqua/features/shared/shared.dart';

/// Provider for managing collateral transactions
final collateralTransactionProvider = StateNotifierProvider<
    CollateralTransactionNotifier, CollateralTransactionState>(
  (ref) {
    final lendingNotifier = ref.read(lendingProvider.notifier);
    final liquidNotifier = ref.watch(liquidProvider);
    return CollateralTransactionNotifier(
      lendingNotifier: lendingNotifier,
      liquidNotifier: liquidNotifier,
    );
  },
);

/// Notifier for managing collateral transactions
class CollateralTransactionNotifier
    extends StateNotifier<CollateralTransactionState> {
  final LendingNotifier lendingNotifier;
  final LiquidProvider liquidNotifier;

  CollateralTransactionNotifier({
    required this.lendingNotifier,
    required this.liquidNotifier,
  }) : super(const CollateralTransactionState());

  /// Get the PSBT for claiming collateral
  Future<void> getPsbt(String contractId, int feeRate) async {
    state = state.copyWith(psbt: const AsyncValue.loading());
    try {
      final psbt =
          await lendingNotifier.getClaimCollateralPsbt(contractId, feeRate);
      state = state.copyWith(psbt: AsyncValue.data(psbt.psbt));
    } catch (error, stackTrace) {
      state = state.copyWith(psbt: AsyncValue.error(error, stackTrace));
    }
  }

  /// Sign the PSBT with the wallet
  Future<void> signPsbt(String psbt) async {
    state = state.copyWith(signedTx: const AsyncValue.loading());
    try {
      final signDetails = GdkSignPsbtDetails(
        psbt: psbt,
        utxos: [], // Empty list since we're not spending any UTXOs
      );
      final signedTx = await liquidNotifier.signPsbt(signDetails);
      if (signedTx?.psbt == null) {
        throw Exception('Failed to sign PSBT');
      }
      state = state.copyWith(signedTx: AsyncValue.data(signedTx!.psbt!));
    } catch (error, stackTrace) {
      state = state.copyWith(signedTx: AsyncValue.error(error, stackTrace));
    }
  }

  /// Post the signed transaction
  Future<void> postSignedTx(String contractId, String signedTx) async {
    state = state.copyWith(txid: const AsyncValue.loading());
    try {
      final txid = await lendingNotifier.postClaimTx(contractId, signedTx);
      state = state.copyWith(txid: AsyncValue.data(txid));
    } catch (error, stackTrace) {
      state = state.copyWith(txid: AsyncValue.error(error, stackTrace));
    }
  }

  /// Clear the state
  void clear() {
    state = const CollateralTransactionState();
  }
}
