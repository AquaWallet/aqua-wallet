import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class TopUpSideSheet extends HookWidget {
  const TopUpSideSheet({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.topUp,
      showBackButton: false,
      children: [
        AquaText.body1SemiBold(
          text: loc.exchangeTransferFromTitle,
          color: aquaColors.textPrimary,
        ),
        const SizedBox(height: 16),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                iconLeading: AquaAssetIcon.fromAssetId(
                  assetId: AssetIds.btc,
                  size: 40,
                ),
                colors: aquaColors,
                title: 'BTC Direct',
                titleColor: aquaColors.textPrimary,
                subtitle: 'BTC',
                subtitleColor: aquaColors.textSecondary,
                titleTrailing: '1.94839493',
                titleTrailingColor: aquaColors.textPrimary,
                subtitleTrailing: '\$204,558.51',
                subtitleTrailingColor: aquaColors.textSecondary,
                onTap: () => TopUpAmountSideSheet.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                  assetId: AssetIds.btc,
                ),
              ),
              const Divider(height: 0),
              AquaListItem(
                iconLeading: AquaAssetIcon.fromAssetId(
                  assetId: AssetIds.layer2,
                  size: 40,
                ),
                colors: aquaColors,
                title: 'L2 Bitcoin',
                titleColor: aquaColors.textPrimary,
                subtitle: 'L-BTC',
                subtitleColor: aquaColors.textSecondary,
                titleTrailing: '0.00489438',
                titleTrailingColor: aquaColors.textPrimary,
                subtitleTrailing: '\$204,558.51',
                subtitleTrailingColor: aquaColors.textSecondary,
                onTap: () => TopUpAmountSideSheet.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                  assetId: AssetIds.layer2,
                ),
              ),
              const Divider(height: 0),
              AquaListItem(
                iconLeading: AquaAssetIcon.fromAssetId(
                  assetId: AssetIds.usdtTether,
                  size: 40,
                ),
                colors: aquaColors,
                title: 'BTC Direct',
                titleColor: aquaColors.textPrimary,
                subtitle: 'USDt',
                subtitleColor: aquaColors.textSecondary,
                titleTrailing: '11,020.00',
                titleTrailingColor: aquaColors.textPrimary,
                onTap: () => TopUpAmountSideSheet.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                  assetId: AssetIds.usdtTether,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    return SideSheet.right(
      body: TopUpSideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class TopUpAmountSideSheet extends HookWidget {
  const TopUpAmountSideSheet({
    required this.loc,
    required this.aquaColors,
    required this.assetId,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final String assetId;

  @override
  Widget build(BuildContext context) {
    final selectedAssetId = useState(assetId);
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
      title: loc.topUp,
      onBackPress: () {
        Navigator.pop(context);
        TopUpSideSheet.show(context: context, aquaColors: aquaColors, loc: loc);
      },
      widgetAtBottom: AquaButton.primary(
        text: loc.next,
        onPressed: isButtonEnabled.value
            ? () {
                // Handle next button press when amount is valid
                ConfirmTopUpSideSheet.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                  assetId: assetId,
                );
              }
            : null,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AquaChip.accent(
              label: loc.maxAmount,
              onTap: () {
                ///TODO: apply max amount to text controller that user has for this asset
              },
            ),
            CurrencyDropDownWidget(aquaColors: aquaColors),
          ],
        ),
        const SizedBox(height: 16),
        AquaAssetInputField(
          assets: const [],
          controller: amountTextController,
          ticker: selectedAssetTicker,
          assetId: assetId,
          unit: AquaAssetInputUnit.crypto,
          colors: aquaColors,
          balance: '1.94839493',
          conversionAmount: '0.00',
          showFiatRate: true,
          disabled: false,
          errorController: AquaInputErrorController(),
          balanceLabel: loc.balanceLabel,
          onChanged: (valueInCrypto) {
            // Update the current amount when the input field changes
            final amount = double.tryParse(valueInCrypto) ?? 0.0;
            currentAmount.value = amount;
            isButtonEnabled.value = amount > 0;
          },
          onAssetSelected: (p0) {},
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    required String assetId,
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: TopUpAmountSideSheet(
        aquaColors: aquaColors,
        loc: loc,
        assetId: assetId,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class ConfirmTopUpSideSheet extends HookWidget {
  const ConfirmTopUpSideSheet({
    required this.loc,
    required this.aquaColors,
    required this.assetId,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final String assetId;

  @override
  Widget build(BuildContext context) {
    final selectedAssetId = useState(assetId);
    final selectedAssetTicker = useMemoized(
      () => switch (selectedAssetId.value) {
        AssetIds.btc => 'BTC',
        AssetIds.layer2 => 'L-BTC',
        _ when (AssetIds.usdtliquid.contains(selectedAssetId.value)) => 'USDt',
        _ => 'USDt',
      },
      [selectedAssetId.value],
    );

    final enabledSliderKey = useState(UniqueKey());
    final sliderState = useState(AquaSliderState.initial);

    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.marketplaceDolphinCardConfirmTopUp,
      onBackPress: () {
        TopUpAmountSideSheet.show(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
          assetId: assetId,
        );
      },
      widgetAtBottom: AquaSlider(
        key: enabledSliderKey.value,
        colors: aquaColors,
        text: 'Slide to Top-up',
        stickToEnd: true,
        sliderState: sliderState.value,
        width: 340,
        onConfirm: () {
          sliderState.value = AquaSliderState.inProgress;
          Future.delayed(const Duration(seconds: 3), () {
            sliderState.value = AquaSliderState.completed;
            Future.delayed(const Duration(seconds: 3), () {
              enabledSliderKey.value = UniqueKey();
            });
          });

          Navigator.pop(context);

          ///[isSuccess] is only  for testing popups
          const isSuccess = false;

          ///TODO: show appropriat model sheet
          ModelSheetFunctionsForDolphinTopUp.showModelSheet(
            context: context,
            aquaColors: aquaColors,
            loc: loc,
            isSuccess: isSuccess,
          );
        },
      ),
      children: [
        AquaTransactionSummary.send(
          assetId: assetId,
          isPending: false,
          assetTicker: selectedAssetTicker,
          amountCrypto: '-0.49584475',
          amountFiat: '-\$4,558.51',
          colors: aquaColors,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AquaFeeTile(
                  title: loc.standard,
                  amountCrypto: '25 Sat/vB',
                  amountFiat: '≈ \$1.9662',
                  isSelected: true,
                  colors: aquaColors,
                  isEnabled: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AquaFeeTile(
                  title: loc.commonFeeratePriority,
                  amountCrypto: '25 Sat/vB',
                  amountFiat: '≈ \$1.9662',
                  isSelected: false,
                  colors: aquaColors,
                  isEnabled: true,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
        CustomFeeButton(
          aquaColors: aquaColors,
          loc: loc,
          //TODO: change with actual data
          args: customFeeInputScreenArguments,
        ),
        const SizedBox(height: 16),
        AquaListItem(
          title: 'Amount with fees',
          titleColor: aquaColors.textPrimary,
          subtitleTrailing: '\$4,559.38',
          subtitleColor: aquaColors.textSecondary,
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    required String assetId,
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: ConfirmTopUpSideSheet(
        aquaColors: aquaColors,
        loc: loc,
        assetId: assetId,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
