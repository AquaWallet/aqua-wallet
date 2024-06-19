import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class AmountParsingException implements ExceptionLocalized {
  final AmountParsingExceptionType type;
  final String? amount;
  final String? customMessage;

  AmountParsingException(this.type, {this.customMessage, this.amount});

  @override
  String toLocalizedString(BuildContext context) {
    switch (type) {
      case AmountParsingExceptionType.emptyAmount:
        return context.loc.sendAssetAmountScreenEmptyAmountError;
      case AmountParsingExceptionType.notEnoughFunds:
        return context.loc.sendAssetAmountScreenNotEnoughFundsError;
      case AmountParsingExceptionType.notEnoughFundsForFee:
        return context.loc.sendAssetAmountScreenNotEnoughFundsForFeeError;
      case AmountParsingExceptionType.belowSendMin:
        return context.loc.sendMinAmountError(amount!);
      case AmountParsingExceptionType.aboveSendMax:
        return context.loc.sendMaxAmountError(amount!);
      case AmountParsingExceptionType.generic:
        return customMessage ?? toString();
      default:
        throw ('Unhandled validation error');
    }
  }
}

enum AmountParsingExceptionType {
  emptyAmount,
  notEnoughFunds,
  notEnoughFundsForFee,
  belowSendMin,
  aboveSendMax,
  generic;
}
