import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/shared/utils/transaction_summary_localizations_extension.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

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

class SwapMainSideSheet extends HookWidget {
  const SwapMainSideSheet({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    final selectedAssetId = useState(AssetIds.btc);
    final selectedAssetTicker = useMemoized(
      () => switch (selectedAssetId.value) {
        AssetIds.btc => 'BTC',
        AssetIds.layer2 => 'L-BTC',
        _ when (AssetIds.usdtliquid.contains(selectedAssetId.value)) => 'USDt',
        _ => 'USDt',
      },
      [selectedAssetId.value],
    );
    final amountTextController = useTextEditingController();
    final currentAmount = useState(0.0);
    final isButtonEnabled = useState(false);
    final selectedQuickActionIndex = useState<int>(0);

    // Listen to amount changes and enable button when amount > 0
    useEffect(() {
      ///TODO: Should also consider max amount that user has for this asset
      void listener() {
        final text = amountTextController.text.trim();
        if (text.isNotEmpty) {
          final amount = double.tryParse(text) ?? 0.0;
          currentAmount.value = amount;
          isButtonEnabled.value = amount > 0;
        } else {
          currentAmount.value = 0.0;
          isButtonEnabled.value = false;
        }
      }

      amountTextController.addListener(listener);
      return () => amountTextController.removeListener(listener);
    }, [amountTextController]);

    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.swap,
      widgetAtBottom: AquaButton.primary(
        text: loc.next,
        onPressed: isButtonEnabled.value
            ? () {
                SwapConfirmSideSheet.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                  fromAssetTicker: AssetIds.btc,
                  toAssetTicker: AssetIds.lbtc.first,
                );
              }
            : null,
      ),
      showBackButton: false,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AquaChip.accent(
              label: loc.maxAmount,
              onTap: () => amountTextController.text = '1.432432412',
            ),
            CurrencyDropDownWidget(
              aquaColors: aquaColors,
              showDropDownIcon: false,
              textBeforeCountryFlag: 'BTC',
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: quickActionItemHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: AquaQuickActionItem(
                        label: loc.swap,
                        foregroundColor: selectedQuickActionIndex.value == 0
                            ? aquaColors.accentBrand
                            : null,
                        onTap: () => selectedQuickActionIndex.value = 0,
                      ),
                    ),
                    const VerticalDivider(width: 0),
                    Expanded(
                      child: AquaQuickActionItem(
                        label: loc.fee,
                        foregroundColor: selectedQuickActionIndex.value == 1
                            ? aquaColors.accentBrand
                            : null,
                        onTap: () => selectedQuickActionIndex.value = 1,
                      ),
                    )
                  ],
                ),
              ),
              const Divider(height: 0),
              if (selectedQuickActionIndex.value == 0) ...[
                SizedBox(
                  height: heightOfSwapMainSideSheet,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          AquaAssetInputField(
                            assets: _assets,
                            controller: amountTextController,
                            ticker: selectedAssetTicker,
                            assetId: selectedAssetId.value,
                            isSwapable: true,
                            unit: AquaAssetInputUnit.crypto,
                            colors: aquaColors,
                            balance: '1.94839493',
                            balanceLabel: loc.balanceLabel,
                            conversionAmount: '0.00',
                            showFiatRate: true,
                            disabled: false,
                            errorController: AquaInputErrorController(
                                const AquaInputError(
                                    label: 'Bal:', amount: '1.94839493')),
                            onChanged: (valueInCrypto) {
                              // Update the current amount when the input field changes
                              final amount =
                                  double.tryParse(valueInCrypto) ?? 0.0;
                              currentAmount.value = amount;
                              isButtonEnabled.value = amount > 0;
                            },
                            onAssetSelected: (assetId) =>
                                selectedAssetId.value = assetId,
                          ),
                          const Divider(height: 0),
                          AquaAssetInputField(
                            assets: _assets,
                            controller: amountTextController,
                            ticker: 'L-BTC',
                            assetId: AssetIds.lbtc.first,
                            balanceLabel: loc.balanceLabel,
                            isSwapable: false,
                            unit: AquaAssetInputUnit.crypto,
                            colors: aquaColors,
                            balance: '1.94839493',
                            conversionAmount: '0.00',
                            showFiatRate: true,
                            disabled: false,
                            errorController: AquaInputErrorController(),
                            onChanged: (valueInCrypto) {
                              // Update the current amount when the input field changes
                              final amount =
                                  double.tryParse(valueInCrypto) ?? 0.0;
                              currentAmount.value = amount;
                              isButtonEnabled.value = amount > 0;
                            },
                            onAssetSelected: (assetId) =>
                                selectedAssetId.value = assetId,
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: sizeofSwapIconContainer,
                          height: sizeofSwapIconContainer,
                          decoration: BoxDecoration(
                            color: aquaColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: AquaIcon.swapVertical(
                            color: aquaColors.textPrimary,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ] else ...[
                AquaListItem(
                  title: 'Conversion Rate',
                  titleColor: aquaColors.textPrimary,
                  subtitle: '99.9%',
                  subtitleColor: aquaColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    return SideSheet.right(
      body: SwapMainSideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class SwapConfirmSideSheet extends HookWidget {
  const SwapConfirmSideSheet({
    required this.loc,
    required this.aquaColors,
    required this.fromAssetTicker,
    required this.toAssetTicker,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final String fromAssetTicker;
  final String toAssetTicker;

  @override
  Widget build(BuildContext context) {
    final enabledSliderKey = useState(UniqueKey());
    final sliderState = useState(AquaSliderState.initial);

    final isTotalFeesExpanded = useState(false);

    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.commonConfirmSwap,
      widgetAtBottom: AquaSlider(
        key: enabledSliderKey.value,
        colors: aquaColors,
        text: 'Slide to Top-up',
        stickToEnd: true,
        sliderState: sliderState.value,
        width: 340,
        onConfirm: () async {
          sliderState.value = AquaSliderState.inProgress;
          Future.delayed(const Duration(seconds: 3), () {
            sliderState.value = AquaSliderState.completed;
            Future.delayed(const Duration(seconds: 3), () {
              enabledSliderKey.value = UniqueKey();
            });
          });

          // Navigator.pop(context);

          await showDialog(
              context: context,
              builder: (context) => const Dialog.fullscreen(
                    child: LoaderScreenWidget(
                      message:
                          'Your swap is in motion, riding the waves to completion!',
                    ),
                  )).then(
            (value) {
              ModelSheetFunctionsForSwap.showSwapModal(
                context: context,
                aquaColors: aquaColors,
                loc: loc,
                type: SwapModalType.complete,
              );
            },
          );

          ///TODO: show appropriat model sheet
        },
      ),
      onBackPress: () {
        Navigator.pop(context);
        SwapMainSideSheet.show(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
        );
      },
      children: [
        AquaSwapTransactionSummary(
          fromAssetId: fromAssetTicker,
          toAssetId: toAssetTicker,
          // fromAssetTicker: 'btc',
          // toAssetTicker: 'l-btc',
          fromAssetTicker: _getAssetTicker(fromAssetTicker),
          toAssetTicker: _getAssetTicker(toAssetTicker),
          fromAmountCrypto: '-0.49584475',
          toAmountCrypto: '+0.49584475',
          isPending: false,
          colors: aquaColors,
          text: loc.transactionSummaryLocalizations,
        ),
        const SizedBox(height: 24),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                colors: aquaColors,
                title: 'SideSwap ID',
                titleColor: aquaColors.textPrimary,
                subtitle: 'TYseuBSHmwzgHthcr18y5a5N8jsYsa4t3H',
                subtitleColor: aquaColors.textSecondary,
                iconTrailing: AquaIcon.copy(
                  color: aquaColors.textSecondary,
                  onTap: () => context
                      .copyToClipboard('TYseuBSHmwzgHthcr18y5a5N8jsYsa4t3H'),
                ),
                onTap: () => context
                    .copyToClipboard('TYseuBSHmwzgHthcr18y5a5N8jsYsa4t3H'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                colors: aquaColors,
                title: loc.totalFees,
                titleColor: aquaColors.textPrimary,
                titleTrailing: '\$3.48',
                titleTrailingColor: aquaColors.textPrimary,
                subtitleTrailing: '0.0000612 BTC',
                subtitleTrailingColor: aquaColors.textSecondary,
                iconTrailing: isTotalFeesExpanded.value
                    ? AquaIcon.chevronUp(
                        color: aquaColors.textSecondary,
                        onTap: () => isTotalFeesExpanded.value =
                            !isTotalFeesExpanded.value,
                      )
                    : AquaIcon.chevronDown(
                        color: aquaColors.textSecondary,
                        onTap: () => isTotalFeesExpanded.value =
                            !isTotalFeesExpanded.value,
                      ),
                onTap: () =>
                    isTotalFeesExpanded.value = !isTotalFeesExpanded.value,
              ),
              if (isTotalFeesExpanded.value) ...[
                const Divider(height: 0),
                AquaListItem(
                  colors: aquaColors,
                  title: loc.internalSendReviewSideswapServiceFee,
                  titleColor: aquaColors.textPrimary,
                  subtitleTrailing: '0.1%',
                  subtitleTrailingColor: aquaColors.textSecondary,
                ),
                const Divider(height: 0),
                if ((fromAssetTicker == AssetIds.btc ||
                        AssetIds.lbtc.contains(fromAssetTicker)) &&
                    (toAssetTicker == AssetIds.btc ||
                        AssetIds.lbtc.contains(toAssetTicker))) ...[
                  AquaListItem(
                    colors: aquaColors,
                    title: 'Bitcoin Network Fee',
                    titleColor: aquaColors.textPrimary,
                    subtitleTrailing: '0.00000059 BTC',
                    subtitleTrailingColor: aquaColors.textSecondary,
                  ),
                  const Divider(height: 0),
                  AquaListItem(
                    colors: aquaColors,
                    title: 'Current Bitcoin Rate',
                    titleColor: aquaColors.textPrimary,
                    subtitleTrailing: '≈7 sats/vbyte',
                    subtitleTrailingColor: aquaColors.textSecondary,
                  ),
                  const Divider(height: 0),
                ],
                AquaListItem(
                  colors: aquaColors,
                  title: loc.liquidNetworkFee,
                  titleColor: aquaColors.textPrimary,
                  subtitleTrailing: '0.00000020 BTC',
                  subtitleTrailingColor: aquaColors.textSecondary,
                ),
                const Divider(height: 0),
                AquaListItem(
                  colors: aquaColors,
                  title: 'Current Liquid Rate',
                  titleColor: aquaColors.textPrimary,
                  subtitleTrailing: '≈0.1 sats/vbyte',
                  subtitleTrailingColor: aquaColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: AquaTypography.body2Medium.copyWith(
              color: aquaColors.textSecondary,
            ),
            children: [
              const TextSpan(
                text:
                    'This is a Peg-in Transaction. Timing depends on network conditions. ',
              ),
              TextSpan(
                text: 'Learn more',
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // Handle learn more tap
                  },
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _getAssetTicker(String assetId) => switch (assetId) {
        AssetIds.btc => 'BTC',
        _ when (AssetIds.lbtc.contains(assetId)) => 'L-BTC',
        _ when (AssetIds.isAnyUsdt(assetId)) => 'USDt',
        AssetIds.lightning => 'Lightning',
        _ => throw UnimplementedError(),
      };

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    required String fromAssetTicker,
    required String toAssetTicker,
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: SwapConfirmSideSheet(
        aquaColors: aquaColors,
        loc: loc,
        fromAssetTicker: fromAssetTicker,
        toAssetTicker: toAssetTicker,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
