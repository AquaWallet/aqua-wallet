import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class AmountParsingException implements ExceptionLocalized {
  final AmountParsingExceptionType type;
  final String? customMessage;

  AmountParsingException(this.type, {this.customMessage});

  @override
  String toLocalizedString(BuildContext context) {
    switch (type) {
      case AmountParsingExceptionType.emptyAmount:
        return context.loc.sendAssetAmountScreenEmptyAmountError;
      case AmountParsingExceptionType.notEnoughFunds:
        return context.loc.sendAssetAmountScreenNotEnoughFundsError;
      case AmountParsingExceptionType.belowBoltzMin:
        return context.loc.boltzMinAmountError(boltzMin.toString());
      case AmountParsingExceptionType.aboveBoltzMax:
        return context.loc.boltzMaxAmountError(boltzMin.toString());
      case AmountParsingExceptionType.belowSideShiftMin:
        return context.loc.sideshiftMinDeliverAmountBasicError;
      case AmountParsingExceptionType.aboveSideShiftMax:
        return context.loc.sideshiftMaxDeliverAmountBasicError;
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
  belowBoltzMin,
  aboveBoltzMax,
  belowSideShiftMin,
  aboveSideShiftMax,
  generic;
}
