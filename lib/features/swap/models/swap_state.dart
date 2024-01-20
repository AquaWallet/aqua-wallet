import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'swap_state.freezed.dart';

@freezed
class SwapState with _$SwapState {
  const factory SwapState.empty() = SwapStateEmpty;
  const factory SwapState.pendingVerification({
    required SwapStartWebResponse data,
  }) = SwapStateVerify;
  const factory SwapState.success({
    required Asset asset,
    required GdkTransaction transaction,
  }) = SwapStateSuccess;
}
