import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class AmountParsingException implements ExceptionLocalized {
  final AmountParsingExceptionType type;
  final String? amount;
  final String? customMessage;
  final String? displayUnitTicker;

  /// Threshold in sats when [amount] is omitted (send flow resolves formatting in UI).
  final int? thresholdSats;

  AmountParsingException(
    this.type, {
    this.customMessage,
    this.amount,
    this.displayUnitTicker,
    this.thresholdSats,
  });

  @override
  String toLocalizedString(BuildContext context) {
    switch (type) {
      case AmountParsingExceptionType.emptyAmount:
        return context.loc.sendAssetAmountScreenEmptyAmountError;
      case AmountParsingExceptionType.belowMin:
      case AmountParsingExceptionType.belowLbtcMin:
        if (amount == null || displayUnitTicker == null) {
          return context.loc.commonSomethingWentWrong;
        }
        return context.loc.amountBelowMin(amount!, displayUnitTicker!);
      case AmountParsingExceptionType.notEnoughFunds:
        return context.loc.sendAssetAmountScreenNotEnoughFundsError;
      case AmountParsingExceptionType.notEnoughFundsForFee:
        return context.loc.sendAssetAmountScreenNotEnoughFundsForFeeError;
      case AmountParsingExceptionType.invalidArguments:
        return context.loc.commonSomethingWentWrong;
      case AmountParsingExceptionType.belowSendMin:
        if (amount == null) {
          return context.loc.commonSomethingWentWrong;
        }
        return context.loc.sendMinAmountError(amount!);
      case AmountParsingExceptionType.aboveSendMax:
        if (amount == null) {
          return context.loc.commonSomethingWentWrong;
        }
        return context.loc.sendMaxAmountError(amount!);
      case AmountParsingExceptionType.generic:
        return customMessage ?? toString();
      default:
        return context.loc.commonSomethingWentWrong;
    }
  }
}

enum AmountParsingExceptionType {
  emptyAmount,
  belowMin,
  belowLbtcMin,
  notEnoughFunds,
  notEnoughFundsForFee,
  belowSendMin,
  aboveSendMax,
  generic,
  invalidArguments;
}
