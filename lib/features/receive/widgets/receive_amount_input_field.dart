import 'package:aqua/common/input_formatters/decimal_text_input_formatter.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/receive/providers/receive_asset_amount_provider.dart';
import 'package:aqua/features/settings/exchange_rate/pages/currency_conversion_settings_screen.dart';
import 'package:aqua/features/settings/exchange_rate/providers/conversion_currencies_provider.dart';
import 'package:aqua/features/settings/exchange_rate/providers/exchange_rate_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/services.dart';

class AmountInputField extends HookConsumerWidget {
  final Asset asset;
  final TextEditingController controller;
  final bool isFiatToggled;

  const AmountInputField({
    super.key,
    required this.asset,
    required this.controller,
    required this.isFiatToggled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRate =
        ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));
    final fiatRates = ref.watch(fiatRatesProvider).unwrapPrevious().valueOrNull;
    final enabledCurrencies =
        ref.watch(conversionCurrenciesProvider).enabledCurrencies;
    final supportedCurrenciesList = fiatRates != null
        ? enabledCurrencies + [context.loc.conversionCurrenciesOtherOption]
        : [currentRate.currency.value];
    final selectedCurrency =
        ref.read(amountCurrencyProvider.notifier).state ?? 'Sats';
    final assetSymbol =
        isFiatToggled ? currentRate.currency.value : asset.ticker;
    final allowedInputRegex = asset.isLightning && !isFiatToggled
        ? RegExp(r'^\d*')
        : RegExp(r'^\d*(\.|\,)?\d*');

    final allConversionOptions = ['Sats', ...supportedCurrenciesList];

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
            if (isFiatToggled) ...[
              // for fiat, limit to 2 decimal places
              DecimalTextInputFormatter(decimalRange: 2)
            ] else if (!asset.isLightning) ...[
              // for bitcoin, limit to 8 decimal places
              DecimalTextInputFormatter(decimalRange: 8)
            ],
          ],
          decoration: Theme.of(context).inputDecoration.copyWith(
                hintText: context.loc.sendAssetAmountScreenAmountHint,
                hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colors.hintTextColor,
                      fontWeight: FontWeight.w400,
                      fontSize: 24.sp,
                    ),
                border: Theme.of(context).inputBorder,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedCurrency == 'Sats') ...[
                      AssetIcon(
                        assetId: asset.id,
                        assetLogoUrl: asset.logoUrl,
                        size: 24.r,
                      ),
                    ],
                    SizedBox(width: 6.w),
                    asset.isNonSatsAsset
                        ? Text(
                            assetSymbol,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: 24.sp,
                                ),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton(
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontSize: 20.sp),
                                items: allConversionOptions
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ))
                                    .toList(),
                                value: selectedCurrency,
                                onChanged: (newSelectedCurrency) {
                                  if (newSelectedCurrency ==
                                      context.loc
                                          .conversionCurrenciesOtherOption) {
                                    Navigator.of(context).pushNamed(
                                        ConversionCurrenciesSettingsScreen
                                            .routeName);
                                  } else if (newSelectedCurrency == 'Sats') {
                                    ref
                                        .read(amountCurrencyProvider.notifier)
                                        .state = null;
                                  } else {
                                    ref
                                        .read(amountCurrencyProvider.notifier)
                                        .state = newSelectedCurrency as String;
                                  }
                                }),
                          ),
                    SizedBox(width: 23.w),
                  ],
                ),
              ),
        ),
      ],
    );
  }
}
