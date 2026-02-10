import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaAmountInputTextField extends HookWidget {
  const AquaAmountInputTextField({
    super.key,
    this.precision = 8,
    this.allowSystemKeyboard = false,
    required this.colors,
    required this.type,
    required this.fiatSymbol,
    this.onChanged,
    this.controller,
    this.decimalSeparator = '.',
  });

  final int precision;
  final AquaColors? colors;
  final AquaAssetInputType type;
  final String fiatSymbol;
  final bool allowSystemKeyboard;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String decimalSeparator;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final isFocused = useState(false);
    final isFiat = type == AquaAssetInputType.fiat;

    useEffect(() {
      void onFocusChange() {
        isFocused.value = focusNode.hasFocus;
      }

      focusNode.addListener(onFocusChange);
      return () => focusNode.removeListener(onFocusChange);
    }, [focusNode]);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      keyboardType: allowSystemKeyboard
          ? const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            )
          : TextInputType.none,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d*([\.|\,])?\d*'),
        ),
        TextInputFormatter.withFunction(
          (oldValue, newValue) {
            // Normalize text by converting custom decimal separator to dot for calculations
            final text = newValue.text.replaceAll(decimalSeparator, '.');
            final decimalIndex = text.indexOf('.');
            final containsDecimal = decimalIndex != -1;
            final overflowing = text.length - decimalIndex - 1 > precision;
            final newText = containsDecimal && overflowing
                ? text.substring(0, decimalIndex + precision + 1)
                : text;
            // Convert back to display format with custom decimal separator
            final displayText = newText.replaceAll('.', decimalSeparator);
            return newValue.copyWith(
              text: displayText,
              selection: TextSelection.collapsed(offset: displayText.length),
            );
          },
        ),
      ],
      style: AquaTypography.h5SemiBold,
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        prefixText:
            isFiat && (isFocused.value || controller?.text.isNotEmpty == true)
                ? fiatSymbol
                : '',
        prefixStyle: AquaTypography.h5SemiBold.copyWith(
          color: colors?.textPrimary,
        ),
        hintText: isFiat
            ? isFocused.value
                ? '0'
                : '${fiatSymbol}0${decimalSeparator}00'
            : '0',
        hintStyle: AquaTypography.h5SemiBold.copyWith(
          color: colors?.textTertiary,
        ),
      ),
    );
  }
}
