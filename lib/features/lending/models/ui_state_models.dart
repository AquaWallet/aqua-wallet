import 'package:aqua/features/lending/models/models.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ui_state_models.freezed.dart';

/// State for collateral transactions
@freezed
class CollateralTransactionState with _$CollateralTransactionState {
  const factory CollateralTransactionState({
    @Default(AsyncValue.loading()) AsyncValue<String> psbt,
    @Default(AsyncValue.loading()) AsyncValue<String> signedTx,
    @Default(AsyncValue.loading()) AsyncValue<String> txid,
  }) = _CollateralTransactionState;
}

@freezed
class LendingState with _$LendingState {
  const factory LendingState({
    @Default(AsyncValue.loading()) AsyncValue<List<LoanOffer>> offers,
    @Default(AsyncValue.loading()) AsyncValue<List<LoanContract>> contracts,
    @Default(AsyncValue.loading()) AsyncValue<String?> apiKey,
    @Default(AsyncValue.data(null)) AsyncValue<LoanOffer?> selectedOffer,
    @Default(false) bool isInitialized,
  }) = _LendingState;
}
