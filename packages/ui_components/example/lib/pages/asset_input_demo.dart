import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/models/models.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

const _btcToUsd = 85308.12;
const _btcToEur = 78659.63;
const _kBalance = 1.94839493;
const _kMaxAmount = 0.004738;
final _assets = <AssetUiModel>[
  AssetUiModel(
    assetId: AssetIds.btc,
    name: 'Bitcoin',
    subtitle: 'BTC',
    amount: '1.94839493',
    amountFiat: '\$204,558.51',
  ),
  AssetUiModel(
    assetId: AssetIds.lbtc.first,
    name: 'L2 Bitcoin',
    subtitle: 'L-BTC',
    amount: '1.94839493',
    amountFiat: '\$204,558.51',
  ),
  AssetUiModel(
    assetId: AssetIds.usdtliquid.first,
    name: 'Tether USDt',
    subtitle: 'Liquid USDt',
    amount: '11,020.00',
    amountFiat: '',
  ),
];

class AssetInputDemoPage extends HookConsumerWidget {
  const AssetInputDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;
    final selectedAssetId = useState(AssetIds.btc);
    final currencySymbol = useState('\$');
    final conversionRate = useState(_btcToUsd);
    final errorController = useMemoized(AquaInputErrorController.new);
    final selectedAssetTicker = useMemoized(
      () => switch (selectedAssetId.value) {
        AssetIds.btc => 'BTC',
        AssetIds.layer2 => 'L-BTC',
        _ when (AssetIds.usdtliquid.contains(selectedAssetId.value)) => 'USDt',
        _ when (AssetIds.lbtc.contains(selectedAssetId.value)) => 'L-BTC',
        _ => 'USDt',
      },
      [selectedAssetId.value],
    );
    final onAmountChanged = useCallback((String value) {
      final amount = double.tryParse(value);
      if (value.isEmpty) {
        errorController.clearError();
        return;
      }
      if (amount == null) {
        errorController.addError('Invalid amount');
      } else if (amount > _kBalance) {
        errorController.addError('Insufficient Funds');
      } else if (amount > _kMaxAmount) {
        errorController.addError('Max: $_kMaxAmount');
      } else {
        errorController.clearError();
      }
    }, [errorController]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssetInputSwitchDemoSection(
            ticker: 'BTC',
            assetId: AssetIds.btc,
            theme: theme,
          ),
          const SizedBox(height: 20),
          _AssetInputSwitchDemoSection(
            ticker: 'L-BTC',
            assetId: AssetIds.lbtc.first,
            theme: theme,
          ),
          const SizedBox(height: 20),
          _AssetInputSwitchDemoSection(
            ticker: 'USDt',
            assetId: AssetIds.usdtliquid.first,
            theme: theme,
          ),
          const SizedBox(height: 40),
          AquaTabBar(
            tabs: const ['USD', 'EUR'],
            onTabChanged: (index) {
              final isUsd = index == 0;
              currencySymbol.value = isUsd ? '\$' : '€';
              conversionRate.value = isUsd ? _btcToUsd : _btcToEur;
            },
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              _AssetInputFieldDemoSection(
                ticker: selectedAssetTicker,
                assetId: selectedAssetId.value,
                theme: theme,
                currencySymbol: currencySymbol.value,
                conversionRate: conversionRate.value,
                errorController: errorController,
                onChange: onAmountChanged,
                onAssetSelected: (assetId) {
                  selectedAssetId.value = assetId;
                },
              ),
              const SizedBox(width: 20),
              _AssetInputFieldDemoSection(
                ticker: selectedAssetTicker,
                assetId: selectedAssetId.value,
                disabled: true,
                theme: theme,
                currencySymbol: currencySymbol.value,
                conversionRate: conversionRate.value,
                errorController: errorController,
                onChange: onAmountChanged,
                onAssetSelected: (assetId) {
                  selectedAssetId.value = assetId;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetInputFieldDemoSection extends StatelessWidget {
  const _AssetInputFieldDemoSection({
    required this.theme,
    required this.ticker,
    required this.assetId,
    required this.currencySymbol,
    required this.conversionRate,
    required this.errorController,
    this.disabled = false,
    this.onChange,
    this.onAssetSelected,
  });

  final String ticker;
  final String assetId;
  final bool disabled;
  final AppTheme theme;
  final String currencySymbol;
  final double conversionRate;
  final AquaInputErrorController errorController;
  final Function(String)? onChange;
  final Function(String)? onAssetSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 343),
      child: Column(
        children: [
          AquaAssetInputField(
            assets: _assets,
            ticker: ticker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            colors: theme.colors,
            balance: _kBalance,
            fiatConversionRate: conversionRate,
            disabled: disabled,
            fiatSymbol: currencySymbol,
            errorController: errorController,
            onChanged: onChange,
            onAssetSelected: onAssetSelected,
          ),
          const SizedBox(height: 29),
          AquaAssetInputField(
            assets: _assets,
            ticker: ticker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            colors: theme.colors,
            balance: _kBalance,
            fiatConversionRate: conversionRate,
            disabled: disabled,
            fiatSymbol: currencySymbol,
            errorController: errorController,
            onChanged: onChange,
            onAssetSelected: onAssetSelected,
            isSwapable: false,
          ),
          const SizedBox(height: 49),
          AquaAssetInputField(
            assets: _assets,
            ticker: ticker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            colors: theme.colors,
            balance: _kBalance,
            fiatConversionRate: conversionRate,
            disabled: disabled,
            fiatSymbol: currencySymbol,
            onAssetSelected: onAssetSelected,
            errorController: AquaInputErrorController('Insufficient Funds'),
          ),
          const SizedBox(height: 29),
          AquaAssetInputField(
            assets: _assets,
            ticker: ticker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            colors: theme.colors,
            balance: _kBalance,
            fiatConversionRate: conversionRate,
            disabled: disabled,
            fiatSymbol: currencySymbol,
            onAssetSelected: onAssetSelected,
            isSwapable: false,
            errorController: AquaInputErrorController('Insufficient Funds'),
          ),
          const SizedBox(height: 49),
          AquaAssetInputField(
            assets: _assets,
            ticker: ticker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            colors: theme.colors,
            balance: _kBalance,
            fiatConversionRate: conversionRate,
            disabled: disabled,
            fiatSymbol: currencySymbol,
            onAssetSelected: onAssetSelected,
            errorController: AquaInputErrorController('Max: 0.004738'),
          ),
          const SizedBox(height: 29),
          AquaAssetInputField(
            assets: _assets,
            ticker: ticker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            colors: theme.colors,
            balance: _kBalance,
            fiatConversionRate: conversionRate,
            disabled: disabled,
            fiatSymbol: currencySymbol,
            onAssetSelected: onAssetSelected,
            isSwapable: false,
            errorController: AquaInputErrorController('Max: 0.004738'),
          ),
          const SizedBox(height: 80),
          AquaAssetInputField(
            assets: _assets,
            ticker: ticker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            type: AquaAssetInputType.fiat,
            colors: theme.colors,
            balance: _kBalance,
            fiatConversionRate: conversionRate,
            disabled: disabled,
            fiatSymbol: currencySymbol,
            onAssetSelected: onAssetSelected,
          ),
          const SizedBox(height: 29),
          AquaAssetInputField(
            assets: _assets,
            ticker: ticker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            type: AquaAssetInputType.fiat,
            colors: theme.colors,
            balance: _kBalance,
            fiatConversionRate: conversionRate,
            disabled: disabled,
            fiatSymbol: currencySymbol,
            onAssetSelected: onAssetSelected,
            isSwapable: false,
          ),
          const SizedBox(height: 49),
          AquaAssetInputField(
            assets: _assets,
            ticker: ticker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            type: AquaAssetInputType.fiat,
            colors: theme.colors,
            balance: _kBalance,
            fiatConversionRate: conversionRate,
            disabled: disabled,
            fiatSymbol: currencySymbol,
            onAssetSelected: onAssetSelected,
            errorController: AquaInputErrorController('Insufficient Funds'),
          ),
          const SizedBox(height: 29),
          AquaAssetInputField(
            assets: _assets,
            ticker: ticker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            type: AquaAssetInputType.fiat,
            colors: theme.colors,
            balance: _kBalance,
            fiatConversionRate: conversionRate,
            disabled: disabled,
            fiatSymbol: currencySymbol,
            onAssetSelected: onAssetSelected,
            isSwapable: false,
            errorController: AquaInputErrorController('Insufficient Funds'),
          ),
          const SizedBox(height: 49),
          AquaAssetInputField(
            assets: _assets,
            ticker: ticker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            type: AquaAssetInputType.fiat,
            colors: theme.colors,
            balance: _kBalance,
            fiatConversionRate: conversionRate,
            disabled: disabled,
            fiatSymbol: currencySymbol,
            onAssetSelected: onAssetSelected,
            errorController: AquaInputErrorController('Max: 0.004738'),
          ),
          const SizedBox(height: 29),
          AquaAssetInputField(
            assets: _assets,
            ticker: ticker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            type: AquaAssetInputType.fiat,
            colors: theme.colors,
            balance: _kBalance,
            fiatConversionRate: conversionRate,
            disabled: disabled,
            fiatSymbol: currencySymbol,
            onAssetSelected: onAssetSelected,
            isSwapable: false,
            errorController: AquaInputErrorController('Max: 0.004738'),
          ),
        ],
      ),
    );
  }
}

class _AssetInputSwitchDemoSection extends StatelessWidget {
  const _AssetInputSwitchDemoSection({
    required this.assetId,
    required this.ticker,
    required this.theme,
  });

  final String assetId;
  final String ticker;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AquaAssetInputSwitch(
          onTap: () {},
          colors: theme.colors,
          assetId: assetId,
          ticker: ticker,
          unit: AquaAssetInputUnit.crypto,
        ),
        const SizedBox(width: 40),
        AquaAssetInputSwitch(
          onTap: () {},
          colors: theme.colors,
          assetId: assetId,
          ticker: ticker,
          unit: AquaAssetInputUnit.crypto,
          showDropdown: false,
        ),
        const SizedBox(width: 40),
        AquaAssetInputSwitch(
          onTap: () {},
          colors: theme.colors,
          assetId: assetId,
          ticker: ticker,
          unit: AquaAssetInputUnit.sats,
        ),
        const SizedBox(width: 40),
        AquaAssetInputSwitch(
          onTap: () {},
          colors: theme.colors,
          assetId: assetId,
          ticker: ticker,
          unit: AquaAssetInputUnit.sats,
          showDropdown: false,
        ),
        const SizedBox(width: 40),
        AquaAssetInputSwitch(
          onTap: () {},
          colors: theme.colors,
          assetId: assetId,
          ticker: ticker,
          unit: AquaAssetInputUnit.bits,
        ),
        const SizedBox(width: 40),
        AquaAssetInputSwitch(
          onTap: () {},
          colors: theme.colors,
          assetId: assetId,
          ticker: ticker,
          unit: AquaAssetInputUnit.bits,
          showDropdown: false,
        ),
      ],
    );
  }
}
