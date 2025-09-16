import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SendAssetAmountInput extends HookWidget {
  const SendAssetAmountInput({
    super.key,
    required this.controller,
    required this.symbol,
    required this.onChanged,
    required this.onCurrencyTypeToggle,
    this.allowUsdToggle = true,
    this.disabled = false,
    required this.precision,
    this.backgroundColor,
  });

  final TextEditingController controller;
  final String symbol;
  final void Function(String) onChanged;
  final void Function() onCurrencyTypeToggle;
  final bool allowUsdToggle;
  final bool disabled;
  final int precision;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final onAmountCleared = useCallback(() {
      controller.clear();
      onChanged('');
    });
    return Container(
      decoration: Theme.of(context).solidBorderDecoration.copyWith(
            color: backgroundColor ??
                Theme.of(context).colors.addressFieldContainerBackgroundColor,
          ),
      //ANCHOR - Amount Input
      child: TextField(
        enabled: !disabled,
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 24.0,
            ),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*(\.|\,)?\d*')),
          TextInputFormatter.withFunction(
            (oldValue, newValue) {
              final text = newValue.text.replaceAll(',', '.');
              final decimalIndex = text.indexOf('.');
              final containsDecimal = decimalIndex != -1;
              final overflowing = text.length - decimalIndex - 1 > precision;
              final newText = containsDecimal && overflowing
                  ? text.substring(0, decimalIndex + precision + 1)
                  : text;
              return newValue.copyWith(
                text: newText,
                selection: TextSelection.collapsed(offset: newText.length),
              );
            },
          ),
        ],
        decoration: Theme.of(context).inputDecoration.copyWith(
              filled: false,
              hintText: context.loc.setAmount,
              hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colors.hintTextColor,
                    fontWeight: FontWeight.w700,
                  ),
              border: Theme.of(context).inputBorder,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.text.isNotEmpty && !disabled) ...[
                    //ANCHOR - Clear Amount
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: ClearInputButton(onTap: onAmountCleared),
                    ),
                    const SizedBox(width: 14.0),
                  ],
                  //ANCHOR - Symbol
                  Text(
                    symbol,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 24.0,
                        ),
                  ),
                  const SizedBox(width: 14.0),
                  //ANCHOR - Input Type Toggle Button
                  if (allowUsdToggle) ...[
                    AssetCurrencyTypeToggleButton(onTap: onCurrencyTypeToggle),
                  ],
                  const SizedBox(width: 16.0),
                ],
              ),
            ),
      ),
    );
  }
}
