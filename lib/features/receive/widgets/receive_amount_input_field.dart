import 'package:coin_cz/common/input_formatters/decimal_text_input_formatter.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/receive/providers/receive_asset_amount_provider.dart';
import 'package:coin_cz/features/settings/exchange_rate/pages/currency_conversion_settings_screen.dart';
import 'package:coin_cz/features/settings/exchange_rate/providers/conversion_currencies_provider.dart';
import 'package:coin_cz/features/settings/exchange_rate/providers/exchange_rate_provider.dart';
import 'package:coin_cz/features/settings/manage_assets/models/assets.dart';
import 'package:coin_cz/features/receive/keys/receive_screen_keys.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
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
    final supportedCurrenciesList =
        fiatRates != null && enabledCurrencies.isNotEmpty
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
          key: ReceiveAssetKeys.receiveAssetSetAmountInputField,
          controller: controller,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 24.0,
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
                hintText: context.loc.setAmount,
                hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colors.hintTextColor,
                      fontWeight: FontWeight.w400,
                      fontSize: 24.0,
                    ),
                border: Theme.of(context).inputBorder,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedCurrency == 'Sats') ...[
                      AssetIcon(
                        assetId: asset.id,
                        assetLogoUrl: asset.logoUrl,
                        size: 24.0,
                      ),
                    ],
                    const SizedBox(width: 6.0),
                    asset.isNonSatsAsset
                        ? Text(
                            assetSymbol,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: 24.0,
                                ),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton(
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontSize: 20.0),
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
                                    context.push(
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
                    const SizedBox(width: 23.0),
                  ],
                ),
              ),
        ),
      ],
    );
  }
}
