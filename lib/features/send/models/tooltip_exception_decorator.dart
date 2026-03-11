import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/address_validator/models/amount_parsing_exception.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';

// Decorator for exception messages that are displayed in the tooltip
class TooltipExceptionDecorator implements ExceptionLocalized {
  final ExceptionLocalized _originalException;

  TooltipExceptionDecorator(this._originalException);

  @override
  String toLocalizedString(BuildContext context) {
    if (_originalException is AmountParsingException) {
      final amountException = _originalException;

      switch (amountException.type) {
        case AmountParsingExceptionType.belowLbtcMin:
        case AmountParsingExceptionType.belowMin:
        case AmountParsingExceptionType.belowSendMin:
          return context.loc.sendMinAmountErrorTooltip;
        case AmountParsingExceptionType.aboveSendMax:
          return context.loc.sendMaxAmountErrorTooltip;
        default:
          return _originalException.toLocalizedString(context);
      }
    }

    return _originalException.toLocalizedString(context);
  }
}
