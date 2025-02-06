import 'package:aqua/common/common.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class FeeTransactionNotFoundError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.feeTransactionNotFoundError;
}

class FeeNotFoundError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.feeNotFoundError;
}

class FeeRateNotFoundError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.feeRateNotFoundError;
}

class UnknownTransactionSizeError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.unknownTransactionSizeError;
}

class FeeAssetMismatchError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.feeAssetMismatchError;
}

class TransactionSizeNotFoundError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.transactionSizeNotFoundError;
}
