import 'package:aqua/features/depix/models/depix_models.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/components/chip_label/chip_label.dart';

extension EulenDepositStatusExt on EulenDepositStatus {
  String label(BuildContext context) {
    return switch (this) {
      EulenDepositStatus.canceled => context.loc.depixDepositStatusCanceled,
      EulenDepositStatus.underReview =>
        context.loc.depixDepositStatusUnderReview,
      EulenDepositStatus.depixSent => context.loc.depixDepositStatusDepixSent,
      EulenDepositStatus.error => context.loc.depixDepositStatusError,
      EulenDepositStatus.refunded => context.loc.depixDepositStatusRefunded,
      EulenDepositStatus.expired => context.loc.depixDepositStatusExpired,
      EulenDepositStatus.pending => context.loc.depixDepositStatusPending,
      EulenDepositStatus.pendingPix2fa =>
        context.loc.depixDepositStatusPendingPix2fa,
      EulenDepositStatus.delayed => context.loc.depixDepositStatusDelayed,
      EulenDepositStatus.unknown => context.loc.depixDepositStatusUnknown,
    };
  }

  AquaChipLabelVariant statusVariant(EulenDepositStatus status) =>
      switch (status) {
        EulenDepositStatus.depixSent => AquaChipLabelVariant.success,
        EulenDepositStatus.pending ||
        EulenDepositStatus.pendingPix2fa ||
        EulenDepositStatus.underReview ||
        EulenDepositStatus.delayed ||
        EulenDepositStatus.unknown =>
          AquaChipLabelVariant.warning,
        EulenDepositStatus.canceled ||
        EulenDepositStatus.error ||
        EulenDepositStatus.expired =>
          AquaChipLabelVariant.error,
        EulenDepositStatus.refunded => AquaChipLabelVariant.normal,
      };
}
