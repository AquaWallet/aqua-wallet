import 'package:aqua/common/common.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class ProfileGeneralErrorException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.loginScreenGeneralError;
}

class ProfileAuthErrorException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.loginScreenAuthError;
}

class TopUpInvoiceGenerationException implements ExceptionLocalized {
  TopUpInvoiceGenerationException({this.message});

  final String? message;

  @override
  String toLocalizedString(BuildContext context) =>
      message ?? context.loc.failedToGenerateInvoice;
}
