import 'package:aqua/common/common.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class RbfTransactionNotFoundException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.transactionNotFound;
}

class RbfAmountBelowMinimum implements ExceptionLocalized {
  const RbfAmountBelowMinimum({required this.minFeeRate});

  final int minFeeRate;

  @override
  String toLocalizedString(BuildContext context) => context.loc
      .sendAssetReviewScreenConfirmCustomFeeMinimum(minFeeRate.toInt());
}

class RbfTransactionVsizeNotFoundException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.transactionSizeNotFoundError;
}

class RbfFeeRateNotFoundException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.feeRateNotFoundError;
}
