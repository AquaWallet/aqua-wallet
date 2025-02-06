import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/wallet/utils/derivation_path_utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shared_subaccount.freezed.dart';

/// Shared subaccount model for both Bitcoin and Liquid
/// This is a convenience model dictated by our UI
/// When a user switches subaccounts, they are really selecting the Account index in the derivation path,
///   and we want to keep this Account index in sync for both Bitcoin and Liquid
/// The default Purpose index is 84 for native segwit (P2WPKH), however, we want to support legacy Purpose indeces as well.
@freezed
class SharedSubaccount with _$SharedSubaccount {
  const factory SharedSubaccount({
    @Default(DerivPathPurpose.bip84)
    DerivPathPurpose purpose, // default to BIP84 for native segwit (P2WPKH)
    required int account,
  }) = _SharedSubaccount;

  const SharedSubaccount._();

  GdkSubaccountTypeEnum get gdkSubaccountType => purpose.gdkSubaccountType;
}
