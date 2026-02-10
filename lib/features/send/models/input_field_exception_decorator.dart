import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/address_validator/models/amount_parsing_exception.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';

/// Decorator for exception messages that are displayed in the input field
class InputFieldExceptionDecorator implements ExceptionLocalized {
  final ExceptionLocalized _originalException;
  final String value;

  InputFieldExceptionDecorator(this._originalException, this.value);

  @override
  String toLocalizedString(BuildContext context) {
    if (_originalException is AmountParsingException) {
      final amountException = _originalException;

      switch (amountException.type) {
        case AmountParsingExceptionType.belowLbtcMin:
        case AmountParsingExceptionType.belowMin:
        case AmountParsingExceptionType.belowSendMin:
          final displayValue = amountException.amount ?? value;
          return context.loc.minValue(displayValue);
        case AmountParsingExceptionType.aboveSendMax:
          final displayValue = amountException.amount ?? value;
          return context.loc.maxValue(displayValue);
        case AmountParsingExceptionType.notEnoughFunds:
        case AmountParsingExceptionType.notEnoughFundsForFee:
          final displayValue = amountException.amount ?? value;
          return context.loc.balanceValue(displayValue);
        default:
          return _originalException.toLocalizedString(context);
      }
    }

    return _originalException.toLocalizedString(context);
  }
}
