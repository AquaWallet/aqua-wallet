import 'package:aqua/config/config.dart';
import 'package:aqua/features/receive/pages/models/receive_asset_extensions.dart';
import 'package:aqua/features/receive/providers/receive_asset_amount_provider.dart';
import 'package:aqua/features/send/widgets/asset_currency_type_toggle_button.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';

class AmountInputField extends HookConsumerWidget {
  final Asset asset;
  final TextEditingController controller;
  final bool isFiatToggled;

  const AmountInputField({
    Key? key,
    required this.asset,
    required this.controller,
    required this.isFiatToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // asset symbol
    final assetSymbol = isFiatToggled
        ? AppLocalizations.of(context)!.sendAssetAmountScreenAmountUnitUsd
        : asset.ticker;
    final allowedInputRegex = asset.isLightning && !isFiatToggled
        ? RegExp(r'^\d*')
        : RegExp(r'^\d*(\.|\,)?\d*');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Input Field
        TextField(
          controller: controller,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 24.sp,
              ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(allowedInputRegex),
            TextInputFormatter.withFunction(
              (oldValue, newValue) => newValue.copyWith(
                text: newValue.text.replaceAll(',', '.'),
              ),
            ),
          ],
          decoration: Theme.of(context).inputDecoration.copyWith(
                hintText: AppLocalizations.of(context)!
                    .sendAssetAmountScreenAmountHint,
                hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colors.hintTextColor,
                      fontWeight: FontWeight.w400,
                      fontSize: 24.sp,
                    ),
                border: Theme.of(context).inputBorder,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isFiatToggled) ...[
                      AssetIcon(
                        assetId: asset.id,
                        assetLogoUrl: asset.logoUrl,
                        size: 24.r,
                      ),
                    ],
                    SizedBox(width: 6.w),
                    Text(
                      assetSymbol,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 24.sp,
                          ),
                    ),
                    SizedBox(width: 14.w),
                    if (asset.shouldAllowFiatToggleOnReceive) ...[
                      AssetCurrencyTypeToggleButton(onTap: () {
                        ref
                            .read(amountEnteredIsFiatToggledProvider.notifier)
                            .state = !isFiatToggled;
                      }),
                    ],
                    SizedBox(width: 23.w),
                  ],
                ),
              ),
        ),
      ],
    );
  }
}
