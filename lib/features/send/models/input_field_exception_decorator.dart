import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/address_validator/models/amount_parsing_exception.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

/// Decorator for exception messages that are displayed in the input field
class InputFieldExceptionDecorator implements ExceptionLocalized {
  final ExceptionLocalized _originalException;
  final String value;

  InputFieldExceptionDecorator(this._originalException, this.value);

  @override
  String toLocalizedString(BuildContext context) {
    final e = toAquaInputError(context);
    return e.amount != null ? '${e.label} ${e.amount}' : e.label;
  }

  AquaInputError toAquaInputError(BuildContext context) {
    if (_originalException is AmountParsingException) {
      final amountException = _originalException;
      final displayValue = amountException.amount ?? value;

      switch (amountException.type) {
        case AmountParsingExceptionType.belowLbtcMin:
        case AmountParsingExceptionType.belowMin:
        case AmountParsingExceptionType.belowSendMin:
          return AquaInputError(
              label: context.loc.minLabel, amount: displayValue);
        case AmountParsingExceptionType.aboveSendMax:
          return AquaInputError(
              label: context.loc.maxLabel, amount: displayValue);
        case AmountParsingExceptionType.notEnoughFunds:
        case AmountParsingExceptionType.notEnoughFundsForFee:
          return AquaInputError(
              label: context.loc.balanceLabel, amount: displayValue);
        default:
          return AquaInputError(
              label: _originalException.toLocalizedString(context));
      }
    }

    return AquaInputError(label: _originalException.toLocalizedString(context));
  }
}
