import 'package:aqua/config/config.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';

class SendAssetAmountInput extends HookConsumerWidget {
  const SendAssetAmountInput({
    super.key,
    required this.controller,
    required this.symbol,
    this.allowUsdToggle = true,
    this.disabled = false,
  });

  final TextEditingController controller;
  final String symbol;
  final bool allowUsdToggle;
  final bool disabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: Theme.of(context).solidBorderDecoration,
      //ANCHOR - Address Input
      child: TextField(
        enabled: !disabled,
        controller: controller,
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
            (oldValue, newValue) => newValue.copyWith(
              text: newValue.text.replaceAll(',', '.'),
            ),
          ),
        ],
        decoration: Theme.of(context).inputDecoration.copyWith(
              hintText:
                  AppLocalizations.of(context)!.sendAssetAmountScreenAmountHint,
              hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colors.hintTextColor,
                    fontWeight: FontWeight.w400,
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
                    AssetCurrencyTypeToggleButton(onTap: () {
                      ref.read(userEnteredAmountIsUsdProvider.notifier).state =
                          !ref.read(userEnteredAmountIsUsdProvider);
                    }),
                  ],
                  SizedBox(width: 16.w),
                ],
              ),
            ),
      ),
    );
  }
}
