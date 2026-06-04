import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class DepixLiquidAddressNotFoundError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.depixLiquidAddressNotFoundError;
}

class DepixDepositRequestFailedError extends ExceptionLocalized {
  DepixDepositRequestFailedError({
    required this.statusCode,
    this.responseError,
  });

  final int statusCode;
  final Object? responseError;

  @override
  String toLocalizedString(BuildContext context) {
    final details = responseError != null ? '\n$responseError' : '';
    return '${context.loc.depixDepositRequestFailedError}\n'
        'HTTP $statusCode$details';
  }

  @override
  String toString() =>
      'DepixDepositRequestFailedError(statusCode: $statusCode, error: $responseError)';
}

class DepixPendingDepositMissingPayloadError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      '${context.loc.depixDepositRequestFailedError}\nmissing QR payload';
}
