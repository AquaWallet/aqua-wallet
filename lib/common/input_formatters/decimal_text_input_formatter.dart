// From https://stackoverflow.com/a/54456978
import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter(
      {required this.decimalRange, this.integerRange = 10});

  final int decimalRange;
  final int integerRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (decimalRange == 0) {
      return TextEditingValue(
        text: newValue.text,
        selection: newValue.selection,
        composing: TextRange.empty,
      );
    }

    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Do not allow multiple consecutive zeros at the start of input e.g. 00123
    if (newValue.text.startsWith(RegExp(r'^(0{2,})'))) {
      return oldValue;
    }

    // Prefix with zero if decimal is pressed as the first digit
    if (newValue.text.startsWith('.')) {
      return newValue.copyWith(
        text: newValue.text.replaceFirst('.', '0.'),
        selection: newValue.selection.copyWith(
          baseOffset: 2,
          extentOffset: 2,
        ),
      );
    }

    // Truncate positive numbers that start with a zero e.g. 0123 -> 123
    if (newValue.text.startsWith(RegExp(r'^(0[1-9])'))) {
      return newValue.copyWith(
        text: newValue.text.replaceFirst('0', ''),
        selection: newValue.selection.copyWith(
          baseOffset: 3,
          extentOffset: 3,
        ),
      );
    }

    final decimalValue = Decimal.tryParse(newValue.text);
    if (decimalValue == null) {
      return oldValue;
    }

    var newSelection = newValue.selection;
    var truncated = newValue.text;

    var value = newValue.text;

    if (value.contains('.') &&
        value.substring(value.indexOf('.') + 1).length > decimalRange) {
      truncated = oldValue.text;
      newSelection = oldValue.selection;
    } else if (value == '.') {
      truncated = '0.';

      newSelection = newValue.selection.copyWith(
        baseOffset: min(truncated.length, truncated.length + 1),
        extentOffset: min(truncated.length, truncated.length + 1),
      );
    } else {
      if (value.contains('.')) {
        final index = value.indexOf('.');
        final sub = value.substring(0, index);
        if (sub.length > integerRange) {
          truncated = oldValue.text;
          newSelection = oldValue.selection;
        }
      } else if (value.length > integerRange) {
        truncated = oldValue.text;
        newSelection = oldValue.selection;
      }
    }

    return TextEditingValue(
      text: truncated,
      selection: newSelection,
      composing: TextRange.empty,
    );
  }
}
