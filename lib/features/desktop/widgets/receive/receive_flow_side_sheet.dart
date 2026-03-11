import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/extensions.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class ReceiveFlowSideSheet extends HookWidget {
  const ReceiveFlowSideSheet({
    required this.loc,
    required this.aquaColors,
    required this.assetId,
    required this.nameOfAsset,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final String assetId;
  final String nameOfAsset;

  @override
  Widget build(BuildContext context) {
    const mockCode =
        'bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297';

    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: nameOfAsset,
      onBackPress: () {
        Navigator.pop(context);
        ReceiveSelectorSideSheet.show(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
        );
      },
      widgetAtBottom: _ShareAndCopyAddress(
        aquaColors: aquaColors,
        loc: loc,
        address: mockCode,
      ),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 36),
          decoration: BoxDecoration(
            color: aquaColors.surfacePrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaAssetQRCode(
                content: mockCode,
                assetId: assetId,
              ),
              const SizedBox(height: 16),
              AquaColoredText(
                text: mockCode,
                style: AquaAddressTypography.body2.copyWith(
                  color: aquaColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                colorType: ColoredTextEnum.coloredIntegers,
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                title: loc.setAmount,
                titleColor: aquaColors.textPrimary,
                iconLeading: AquaIcon.edit(color: aquaColors.textPrimary),
                iconTrailing:
                    AquaIcon.chevronRight(color: aquaColors.textSecondary),
                onTap: () => ReceiveSetAmountSideSheet.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                  assetId: assetId,
                  nameOfAsset: nameOfAsset,
                ),
              ),
              const Divider(height: 0),
              AquaListItem(
                title: loc.receiveAssetScreenGenerateNewAddress,
                titleColor: aquaColors.textPrimary,
                iconLeading: AquaIcon.redo(color: aquaColors.textPrimary),
                iconTrailing:
                    AquaIcon.chevronRight(color: aquaColors.textSecondary),
                onTap: () {},
              )
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
    required String assetId,
    required String nameOfAsset,
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: ReceiveFlowSideSheet(
        aquaColors: aquaColors,
        loc: loc,
        assetId: assetId,
        nameOfAsset: nameOfAsset,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class ReceiveSetAmountSideSheet extends HookWidget {
  const ReceiveSetAmountSideSheet({
    required this.loc,
    required this.aquaColors,
    required this.assetId,
    required this.nameOfAsset,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final String assetId;
  final String nameOfAsset;

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
      title: assetId == AssetIds.lightning
          ? loc.boltzInvoiceAmount
          : loc.setAmount,
      onBackPress: () {
        Navigator.pop(context);
        TopUpSideSheet.show(context: context, aquaColors: aquaColors, loc: loc);
      },
      widgetAtBottom: AquaButton.primary(
        text:
            assetId == AssetIds.lightning ? loc.boltzGenerateInvoice : loc.save,
        onPressed: isButtonEnabled.value
            ? () {
                ReceiveAmountIncludedSideSheet.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                  assetId: assetId,
                  nameOfAsset: nameOfAsset,
                );
              }
            : null,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox.shrink(),
            CurrencyDropDownWidget(aquaColors: aquaColors),
          ],
        ),
        const SizedBox(height: 16),
        OutlineContainer(
          aquaColors: aquaColors,
          child: AquaAssetInputField(
            assets: const [],
            controller: amountTextController,
            ticker: selectedAssetTicker,
            assetId: assetId,
            unit: AquaAssetInputUnit.crypto,
            colors: aquaColors,
            balance: '1.94839493',
            balanceValueText: loc.balanceValue('1.94839493'),
            conversionAmount: '0.00',
            showFiatRate: false,
            disabled: false,
            errorController: AquaInputErrorController(),
            onChanged: (valueInCrypto) {
              // Update the current amount when the input field changes
              final amount = double.tryParse(valueInCrypto) ?? 0.0;
              currentAmount.value = amount;
              isButtonEnabled.value = amount > 0;
            },
            onAssetSelected: (p0) {},
          ),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    required String assetId,
    required String nameOfAsset,
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: ReceiveSetAmountSideSheet(
        aquaColors: aquaColors,
        loc: loc,
        assetId: assetId,
        nameOfAsset: nameOfAsset,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class ReceiveAmountIncludedSideSheet extends HookWidget {
  const ReceiveAmountIncludedSideSheet({
    required this.loc,
    required this.aquaColors,
    required this.assetId,
    required this.nameOfAsset,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final String assetId;
  final String nameOfAsset;

  @override
  Widget build(BuildContext context) {
    const mockCode =
        'bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297';

    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: nameOfAsset,
      onBackPress: () {
        ReceiveSetAmountSideSheet.show(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
          assetId: assetId,
          nameOfAsset: nameOfAsset,
        );
      },
      widgetAtBottom: _ShareAndCopyAddress(
        aquaColors: aquaColors,
        loc: loc,
        address: mockCode,
      ),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 36),
          decoration: BoxDecoration(
            color: aquaColors.surfacePrimary,
            borderRadius: assetId == AssetIds.btc
                ? const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  )
                : BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaAssetQRCode(
                content: mockCode,
                assetId: assetId,
              ),
              const SizedBox(height: 16),
              AquaColoredText(
                text: mockCode,
                style: AquaAddressTypography.body2.copyWith(
                  color: aquaColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                colorType: ColoredTextEnum.coloredIntegers,
              )
            ],
          ),
        ),
        if (assetId == AssetIds.btc) ...[
          const Divider(height: 0),
          AquaListItem(
            title: loc.setAmount,
            titleColor: aquaColors.textPrimary,
            subtitle: '0.0849375 BTC',
            subtitleColor: aquaColors.textSecondary,
            iconLeading: AquaIcon.edit(color: aquaColors.textPrimary),
            iconTrailing:
                AquaIcon.chevronRight(color: aquaColors.textSecondary),
            onTap: () => ReceiveSetAmountSideSheet.show(
              context: context,
              aquaColors: aquaColors,
              loc: loc,
              assetId: assetId,
              nameOfAsset: nameOfAsset,
            ),
          ),
          const Divider(height: 0),
          AquaListItem(
            title: loc.receiveAssetScreenGenerateNewAddress,
            titleColor: aquaColors.textPrimary,
            iconLeading: AquaIcon.refresh(color: aquaColors.textPrimary),
            iconTrailing:
                AquaIcon.chevronRight(color: aquaColors.textSecondary),
            onTap: () {},
          ),
        ],
        if (AssetIds.lbtc.contains(assetId)) ...[
          const SizedBox(height: 24),
          OutlineContainer(
            aquaColors: aquaColors,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AquaListItem(
                  title: loc.setAmount,
                  titleColor: aquaColors.textPrimary,
                  subtitle: '0.0849375 BTC',
                  subtitleColor: aquaColors.textSecondary,
                  iconLeading: AquaIcon.edit(color: aquaColors.textPrimary),
                  iconTrailing:
                      AquaIcon.chevronRight(color: aquaColors.textSecondary),
                  onTap: () => ReceiveSetAmountSideSheet.show(
                    context: context,
                    aquaColors: aquaColors,
                    loc: loc,
                    assetId: assetId,
                    nameOfAsset: nameOfAsset,
                  ),
                ),
                const Divider(height: 0),
                AquaListItem(
                  title: loc.receiveAssetScreenGenerateNewAddress,
                  titleColor: aquaColors.textPrimary,
                  iconLeading: AquaIcon.refresh(color: aquaColors.textPrimary),
                  iconTrailing:
                      AquaIcon.chevronRight(color: aquaColors.textSecondary),
                  onTap: () {},
                )
              ],
            ),
          ),
        ],
        if (assetId == AssetIds.lightning) ...[
          const SizedBox(height: 24),
          AquaText.body2Medium(
            text: loc.assetsReceiveLightningQRSubtitle,
            color: aquaColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    required String assetId,
    required String nameOfAsset,
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: ReceiveAmountIncludedSideSheet(
        aquaColors: aquaColors,
        loc: loc,
        assetId: assetId,
        nameOfAsset: nameOfAsset,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class ReceiveSpecialUsdtSideSheet extends HookWidget {
  const ReceiveSpecialUsdtSideSheet({
    required this.loc,
    required this.aquaColors,
    required this.assetId,
    required this.nameOfAsset,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final String assetId;
  final String nameOfAsset;

  @override
  Widget build(BuildContext context) {
    const mockCode = 'xc58c762b90e8cB5a5802178E26a34Eb33345D7E8';

    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: nameOfAsset,
      onBackPress: () {
        Navigator.pop(context);
        ReceiveSelectorSideSheet.show(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
        );
      },
      widgetAtBottom: _ShareAndCopyAddress(
        aquaColors: aquaColors,
        loc: loc,
        address: mockCode,
      ),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 36),
          decoration: BoxDecoration(
            color: aquaColors.surfacePrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaChip.error(label: getLabelText(), colors: aquaColors),
              const SizedBox(height: 16),
              AquaAssetQRCode(
                content: mockCode,
                assetId: assetId,
              ),
              const SizedBox(height: 16),
              AquaColoredText(
                text: mockCode,
                style: AquaAddressTypography.body2.copyWith(
                  color: aquaColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                colorType: ColoredTextEnum.coloredIntegers,
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                title: loc.commonSingleUseAddress,
                titleColor: aquaColors.textPrimary,
                subtitle: 'Min 77.64 USDt',
                subtitleColor: aquaColors.textSecondary,
                titleTrailing: 'Exp: Jan 9, 2025',
                titleTrailingColor: aquaColors.textPrimary,
                subtitleTrailing: 'Max 4000.00 USDt',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
              const Divider(height: 0),
              AquaListItem(
                title: loc.receiveAssetScreenSwapServiceFee,
                titleColor: aquaColors.textPrimary,
                subtitleTrailing: '1.00%',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
              const Divider(height: 0),
              AquaListItem(
                title: '{Provider} Processing Fee',
                titleColor: aquaColors.textPrimary,
                subtitleTrailing: '~\$3.27',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
              const Divider(height: 0),
              AquaListItem(
                title: '{Provider} ID',
                titleColor: aquaColors.textPrimary,
                subtitle: 'ff3f1a278475v5948a279',
                subtitleColor: aquaColors.textSecondary,
                iconTrailing: AquaIcon.copy(
                  color: aquaColors.textSecondary,
                ),
                onTap: () {
                  context.copyToClipboard('ff3f1a278475v5948a279');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AquaText.body2Medium(
          text: 'USDt sent here is swapped to Liquid assets.',
          color: aquaColors.textTertiary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String getLabelText() {
    switch (assetId) {
      case AssetIds.usdtEth:
        return 'Only for $nameOfAsset (ERC-20)';
      case AssetIds.usdtTrx:
        return 'Only for $nameOfAsset (TRC-20)';
      case AssetIds.usdtBep:
        return 'Only for $nameOfAsset (BEP-20)';
      case AssetIds.usdtSol:
        return 'Only for $nameOfAsset (SPL)';
      case AssetIds.usdtPol:
        return 'Only for $nameOfAsset';
      case AssetIds.usdtTon:
        return 'Only for $nameOfAsset';
      default:
        return '';
    }
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    required String assetId,
    required String nameOfAsset,
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: ReceiveSpecialUsdtSideSheet(
        aquaColors: aquaColors,
        loc: loc,
        assetId: assetId,
        nameOfAsset: nameOfAsset,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class _ShareAndCopyAddress extends StatelessWidget {
  const _ShareAndCopyAddress({
    required this.aquaColors,
    required this.loc,
    required this.address,
  });

  final AquaColors aquaColors;
  final AppLocalizations loc;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              // Share address logic
            },
            child: Column(
              children: [
                AquaIcon.share(
                  color: aquaColors.textPrimary,
                ),
                const SizedBox(height: 2),
                AquaText.caption2SemiBold(
                  text: loc.receiveAssetScreenShare,
                  color: aquaColors.textPrimary,
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: InkWell(
            onTap: () {
              /// Tap to copy address
              context.copyToClipboard(address);
            },
            child: Column(
              children: [
                AquaIcon.copy(
                  color: aquaColors.textPrimary,
                ),
                const SizedBox(height: 2),
                AquaText.caption2SemiBold(
                  text: loc.copyAddress,
                  color: aquaColors.textPrimary,
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
