import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';

class DeliverAmountRequiredException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.sideshiftDeliverAmountRequiredError;
  }
}

class DeliverAmountExceedBalanceException
    implements ExceptionLocalized, OrderError {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.sideshiftDeliverAmountExceedBalanceError;
  }
}

class MinDeliverAmountException implements ExceptionLocalized, OrderError {
  MinDeliverAmountException(this.min, this.assetId);

  final Decimal min;
  final String assetId;

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.sideshiftMinDeliverAmountError('$min');
  }
}

class MaxDeliverAmountException implements ExceptionLocalized, OrderError {
  MaxDeliverAmountException(this.max, this.assetId);

  final Decimal max;
  final String assetId;

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.sideshiftMaxDeliverAmountError('$max');
  }
}

class FeeBalanceException implements ExceptionLocalized, OrderError {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.sideshiftFeeBalanceError;
  }
}

class ReceivingAddressException implements Exception {}

class RefundAddressException implements Exception {}

class MissingPairException implements Exception {}

class MissingPairInfoException implements Exception {}
