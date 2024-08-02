import 'package:aqua/common/input_formatters/comma_text_input_formatter.dart';
import 'package:aqua/common/input_formatters/decimal_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountTextField extends StatelessWidget {
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration? decoration;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final String? text;
  final String? hintText;
  final int precision;
  final TextAlign textAlign;
  final Color? cursorColor;
  final bool autofocus;
  final bool readOnly;
  final bool filled;
  final TextEditingController? controller;

  AmountTextField({
    super.key,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.text,
    this.hintText,
    this.precision = 8,
    this.autofocus = true,
    this.decoration = const InputDecoration(
      isCollapsed: true,
      isDense: true,
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
    ),
    this.style,
    this.hintStyle,
    this.textAlign = TextAlign.start,
    this.cursorColor,
    this.readOnly = false,
    this.filled = false,
    this.controller,
  }) {
    internalController = controller ?? TextEditingController();
  }

  late final TextEditingController internalController;

  @override
  Widget build(BuildContext context) {
    final newTextValue = text ?? '';

    internalController.value = internalController.value.copyWith(
      text: newTextValue,
      selection: TextSelection.collapsed(offset: newTextValue.length),
      composing: TextRange.empty,
    );

    return TextField(
      controller: internalController,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      textAlign: textAlign,
      cursorColor: cursorColor,
      autofocus: autofocus,
      readOnly: readOnly,
      keyboardType: keyboardType ??
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: inputFormatters ??
          [
            CommaTextInputFormatter(),
            if (precision == 0) ...[
              FilteringTextInputFormatter.deny(RegExp('[\\-|,\\ .]')),
            ] else ...[
              FilteringTextInputFormatter.deny(RegExp('[\\-|,\\ ]')),
            ],
            DecimalTextInputFormatter(decimalRange: precision),
          ],
      decoration: decoration?.copyWith(
        filled: filled,
        hintText: hintText,
        hintStyle: hintStyle,
      ),
      style: style ??
          Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
    );
  }
}
