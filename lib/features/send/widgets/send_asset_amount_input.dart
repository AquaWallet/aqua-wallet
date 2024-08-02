import 'package:aqua/config/config.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/services.dart';

class SendAssetAmountInput extends HookConsumerWidget {
  const SendAssetAmountInput({
    super.key,
    required this.controller,
    required this.symbol,
    required this.onChanged,
    required this.onCurrencyTypeToggle,
    this.allowUsdToggle = true,
    this.disabled = false,
    required this.precision,
  });

  final TextEditingController controller;
  final String symbol;
  final void Function(String) onChanged;
  final void Function() onCurrencyTypeToggle;
  final bool allowUsdToggle;
  final bool disabled;
  final int precision;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: Theme.of(context).solidBorderDecoration.copyWith(
            color:
                Theme.of(context).colors.addressFieldContainerBackgroundColor,
          ),
      //ANCHOR - Address Input
      child: TextField(
        enabled: !disabled,
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 24.sp,
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
              hintText: context.loc.sendAssetAmountScreenAmountHint,
              hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colors.hintTextColor,
                    fontWeight: FontWeight.w700,
                  ),
              border: Theme.of(context).inputBorder,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //ANCHOR - Symbol
                  Text(
                    symbol,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 24.sp,
                        ),
                  ),
                  SizedBox(width: 14.w),
                  //ANCHOR - Input Type Toggle Button
                  if (allowUsdToggle) ...[
                    AssetCurrencyTypeToggleButton(onTap: onCurrencyTypeToggle),
                  ],
                  SizedBox(width: 16.w),
                ],
              ),
            ),
      ),
    );
  }
}
