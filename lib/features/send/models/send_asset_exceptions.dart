import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

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
