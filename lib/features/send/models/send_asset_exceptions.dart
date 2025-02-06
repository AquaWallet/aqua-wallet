import 'package:aqua/common/common.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class LightningInvoiceNotFoundError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.lightningInvoiceNotFound;
}

class SideshiftRefundAddressNotFoundError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.sideshiftRefundAddressNotFound;
}

class AquaSendFailedSigningIncompleteTxnError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.failedSigningIncompleteTxn;
}
