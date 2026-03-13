import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class SendFlowSideSheet extends HookWidget {
  const SendFlowSideSheet({
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
    final textController = useTextEditingController();

    final amountTextController = useTextEditingController();

    final textFieldKey = useMemoized(() => GlobalKey());
    final overlayEntry = useRef<OverlayEntry?>(null);

    final isAltUsdt =
        AssetIds.isAnyUsdt(assetId) && !AssetIds.usdtliquid.contains(assetId);

    // Function to hide scan overlay
    void hideScanOverlay() {
      overlayEntry.value?.remove();
      overlayEntry.value = null;
    }

    // Function to show scan overlay
    void showScanOverlay() {
      if (overlayEntry.value != null) return; // Already showing

      final renderBox =
          textFieldKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      overlayEntry.value = OverlayEntry(
        builder: (context) => Positioned(
          left: position.dx,
          top: position.dy + size.height + 8,
          width: size.width,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: heightOfScanOverlay,
              decoration: BoxDecoration(
                color: aquaColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: aquaColors.surfaceBorderPrimary,
                  width: 1,
                ),
              ),
              child: ScanWidget(
                aquaColors: aquaColors,
                onScanned: (scannedAddress) {
                  textController.text = scannedAddress;
                  hideScanOverlay();
                },
                onClose: hideScanOverlay,
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry.value!);
    }

    // Clean up overlay when widget is disposed
    useEffect(() {
      return () {
        overlayEntry.value?.remove();
      };
    }, []);

    final isBtc = AssetIds.btc == assetId;
    final selectedFeeTile = useState<int>(0);

    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.send,
      onBackPress: () {
        Navigator.pop(context);
        SendSelectorSideSheet.show(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
        );
      },
      widgetAtBottom: Column(
        children: [
          if (!isAltUsdt) ...[
            AquaListItem(
              colors: aquaColors,
              title: loc.sendAssetScreenClipboardTitle,
              titleColor: aquaColors.textPrimary,
              iconTrailing: AquaIcon.paste(
                color: aquaColors.textSecondary,
                size: 18,
              ),
              contentWidget: AquaColoredText(
                text:
                    'bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297',
                style: AquaAddressTypography.body2.copyWith(
                  color: aquaColors.textSecondary,
                ),
                colorType: ColoredTextEnum.coloredIntegers,
              ),
              onTap: () => context.copyToClipboard(
                  'bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297'),
            ),
            const SizedBox(height: 16),
          ],
          AquaButton.primary(
            text: loc.next,
            onPressed: () {
              if (isAltUsdt) {
                SendConfirmAltUsdtSideSheet.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                  assetId: assetId,
                );
              } else {
                SendConfirmSideSheet.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                  assetId: assetId,
                );
              }
            },
          ),
        ],
      ),
      children: [
        if (!isAltUsdt) ...[
          AquaTextField(
            key: textFieldKey,
            controller: textController,
            label: 'Recipient Address',
            labelTextColor: aquaColors.textSecondary,
            maxLines: 13,
            trailingIcon: Row(
              children: [
                Container(
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    color: aquaColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: AquaIcon.close(
                    color: aquaColors.textTertiary,
                    onTap: () {
                      textController.clear();
                      hideScanOverlay();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                AquaIcon.scan(
                  color: aquaColors.textPrimary,
                  size: 22,
                  onTap: showScanOverlay,
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (assetId != AssetIds.lightning) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AquaChip.accent(
                label: loc.maxAmount,
                onTap: () {
                  ///TODO: apply max amount to text controller that user has for this asset
                },
              ),
              CurrencyDropDownWidget(
                aquaColors: aquaColors,
                showDropDownIcon: false,
                textBeforeCountryFlag: 'BTC',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: AquaAssetInputField(
              assets: const [],
              controller: amountTextController,
              ticker: _getAssetTicker(assetId),
              assetId: assetId,
              unit: AquaAssetInputUnit.crypto,
              colors: aquaColors,
              balance: '1.94839493',
              balanceLabel: loc.balanceLabel,
              conversionAmount: '0.00',
              showFiatRate: true,
              disabled: false,
              errorController: AquaInputErrorController(),
              onChanged: (valueInCrypto) {
                // Update the current amount when the input field changes
                // final amount = double.tryParse(valueInCrypto) ?? 0.0;
                // currentAmount.value = amount;
                // isButtonEnabled.value = amount > 0;
              },
              onAssetSelected: (p0) {},
            ),
          ),
          if (isAltUsdt) ...[
            const SizedBox(height: 8),
            AquaText.caption1Medium(
              text: 'Range: \$5 - \$2,000',
              color: aquaColors.textSecondary,
            ),
          ],
          if (!isAltUsdt) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AquaFeeTile(
                      icon: isBtc
                          ? null
                          : AquaAssetIcon.fromAssetId(
                              assetId: AssetIds.lbtc.first,
                              size: 18,
                            ),
                      title: isBtc ? loc.standard : 'L-BTC',
                      amountCrypto: '25 Sat/vB',
                      amountFiat: '≈ \$1.9662',
                      isSelected: selectedFeeTile.value == 0,
                      colors: aquaColors,
                      isEnabled: true,
                      onTap: () {
                        selectedFeeTile.value = 0;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AquaFeeTile(
                      icon: isBtc
                          ? null
                          : AquaAssetIcon.fromAssetId(
                              assetId: AssetIds.usdtTether,
                              size: 18,
                            ),
                      title: isBtc ? loc.commonFeeratePriority : 'USDt',
                      amountCrypto: '25 Sat/vB',
                      amountFiat: '≈ \$1.9662',
                      isSelected: selectedFeeTile.value == 1,
                      colors: aquaColors,
                      isEnabled: true,
                      onTap: () {
                        selectedFeeTile.value = 1;
                      },
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
          ],
        ],
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
      body: SendFlowSideSheet(
        aquaColors: aquaColors,
        loc: loc,
        assetId: assetId,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class SendConfirmSideSheet extends HookWidget {
  const SendConfirmSideSheet({
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
    final enabledSliderKey = useState(UniqueKey());
    final sliderState = useState(AquaSliderState.initial);
    final noteAdded = useState<String>('');
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: 'Confirm Send',
      onBackPress: () {
        SendFlowSideSheet.show(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
          assetId: assetId,
        );
      },
      widgetAtBottom: AquaSlider(
        key: enabledSliderKey.value,
        colors: aquaColors,
        text: 'Slide to Send',
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
                          'Your send is in motion, riding the waves to completion!',
                    ),
                  )).then(
            (value) {
              ///[isSuccess] is only  for testing popups
              const isSuccess = true;

              ///TODO: show appropriat model sheet
              ModelSheetFunctionsForSend.showModelSheet(
                context: context,
                aquaColors: aquaColors,
                loc: loc,
                isSuccess: isSuccess,
              );
            },
          );
        },
      ),
      children: [
        AquaTransactionSummary.send(
          assetId: assetId,
          isPending: false,
          assetTicker: _getAssetTicker(assetId),
          amountCrypto: '-0.49584475',
          amountFiat: '-\$4,558.51',
          colors: aquaColors,
        ),
        const SizedBox(height: 16),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                colors: aquaColors,
                title: 'Recipient',
                titleColor: aquaColors.textPrimary,
                contentWidget: AquaColoredText(
                  text:
                      'VJLJvmTAy62ZnKT5abXgQxjD9CADkCHYfsCvTEBGdhZ6zuMLbqxidyqoKe2ygdMhVwsYUdQUqkMatHgf (Copied)',
                  style: AquaAddressTypography.body2.copyWith(
                    color: aquaColors.textSecondary,
                  ),
                  colorType: ColoredTextEnum.coloredIntegers,
                ),
                iconTrailing: AquaIcon.copy(
                  color: aquaColors.textSecondary,
                  size: 18,
                  onTap: () => context.copyToClipboard(
                      'VJLJvmTAy62ZnKT5abXgQxjD9CADkCHYfsCvTEBGdhZ6zuMLbqxidyqoKe2ygdMhVwsYUdQUqkMatHgf'),
                ),
              ),
              const Divider(height: 0),
              if (assetId == AssetIds.lightning) ...[
                AquaListItem(
                  colors: aquaColors,
                  title: loc.boltzTotalFees,
                  titleColor: aquaColors.textPrimary,
                  titleTrailing: '\$3.48',
                  titleTrailingColor: aquaColors.textPrimary,
                  subtitleTrailing: '0.0000612 BTC',
                  subtitleTrailingColor: aquaColors.textSecondary,
                ),
                const Divider(height: 0),
                AquaListItem(
                  colors: aquaColors,
                  title: loc.boltzServiceFee,
                  titleColor: aquaColors.textPrimary,
                  subtitleTrailing: '0.1%',
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
              ] else ...[
                AquaListItem(
                  colors: aquaColors,
                  title: 'Add Note',
                  titleColor: aquaColors.textPrimary,
                  iconLeading: AquaIcon.edit(
                    color: aquaColors.textPrimary,
                  ),
                  subtitle: noteAdded.value.isEmpty ? '' : noteAdded.value,
                  subtitleColor: aquaColors.textSecondary,
                  iconTrailing: AquaIcon.chevronRight(
                    color: aquaColors.textSecondary,
                    size: 18,
                  ),
                  onTap: () async {
                    final result = await AquaBottomSheet.show(
                      context,
                      colors: aquaColors,
                      content: CustomModelSheetWidget(
                        aquaColors: aquaColors,
                        loc: loc,
                      ),
                    );
                    noteAdded.value = result ?? '';
                  },
                ),
              ],
            ],
          ),
        ),
        if (assetId == AssetIds.lightning) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AquaText.body1SemiBold(
                  text: 'Lightning Swap Details',
                  color: aquaColors.textPrimary,
                ),
                AquaIcon.infoCircle(
                  color: aquaColors.textPrimary,
                ),
              ],
            ),
          ),
          OutlineContainer(
            aquaColors: aquaColors,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AquaListItem(
                  colors: aquaColors,
                  title: loc.provider,
                  titleColor: aquaColors.textPrimary,
                  subtitleTrailing: 'Boltz.Exchange',
                  subtitleTrailingColor: aquaColors.accentBrand,
                  iconTrailing: AquaIcon.externalLink(
                    color: aquaColors.textSecondary,
                    size: 18,
                  ),
                ),
                const Divider(height: 0),
                AquaListItem(
                  colors: aquaColors,
                  title: loc.boltzId,
                  titleColor: aquaColors.textPrimary,
                  subtitle: 'kgURxBaDI8QK',
                  subtitleColor: aquaColors.textSecondary,
                  iconTrailing: AquaIcon.copy(
                    color: aquaColors.textSecondary,
                    size: 18,
                  ),
                  onTap: () => context.copyToClipboard('kgURxBaDI8QK'),
                ),
              ],
            ),
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
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: SendConfirmSideSheet(
        aquaColors: aquaColors,
        loc: loc,
        assetId: assetId,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class SendConfirmAltUsdtSideSheet extends HookWidget {
  const SendConfirmAltUsdtSideSheet({
    required this.loc,
    required this.aquaColors,
    required this.assetId,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final String assetId;

  get _getNameOfAltAsset => switch (assetId) {
        AssetIds.usdtEth => 'Ethereum',
        AssetIds.usdtTrx => 'Tron',
        AssetIds.usdtBep => 'Binance',
        AssetIds.usdtSol => 'Solana',
        AssetIds.usdtPol => 'Polygon',
        AssetIds.usdtTon => 'Ton',
        _ => 'USDt',
      };

  @override
  Widget build(BuildContext context) {
    final enabledSliderKey = useState(UniqueKey());
    final sliderState = useState(AquaSliderState.initial);
    final selectedFeeTile = useState<int>(0);
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: 'Confirm Send',
      onBackPress: () {
        SendFlowSideSheet.show(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
          assetId: assetId,
        );
      },
      widgetAtBottom: AquaSlider(
        key: enabledSliderKey.value,
        colors: aquaColors,
        text: 'Slide to Send',
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
                          'Your send is in motion, riding the waves to completion!',
                    ),
                  )).then(
            (value) {
              ///[isSuccess] is only  for testing popups
              const isSuccess = true;

              ///TODO: show appropriat model sheet
              ModelSheetFunctionsForSend.showModelSheet(
                context: context,
                aquaColors: aquaColors,
                loc: loc,
                isSuccess: isSuccess,
              );
            },
          );
        },
      ),
      children: [
        AquaTransactionSummary.send(
          assetId: assetId,
          isPending: false,
          assetTicker: _getAssetTicker(assetId),
          amountCrypto: '-0.49584475',
          amountFiat: '-\$4,558.51',
          colors: aquaColors,
        ),
        const SizedBox(height: 16),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                colors: aquaColors,
                title: 'Recipient',
                titleColor: aquaColors.textPrimary,
                contentWidget: AquaColoredText(
                  text:
                      'VJLJvmTAy62ZnKT5abXgQxjD9CADkCHYfsCvTEBGdhZ6zuMLbqxidyqoKe2ygdMhVwsYUdQUqkMatHgf (Copied)',
                  style: AquaAddressTypography.body2.copyWith(
                    color: aquaColors.textSecondary,
                  ),
                  colorType: ColoredTextEnum.coloredIntegers,
                ),
                iconTrailing: AquaIcon.copy(
                  color: aquaColors.textSecondary,
                  size: 18,
                  onTap: () => context.copyToClipboard(
                      'VJLJvmTAy62ZnKT5abXgQxjD9CADkCHYfsCvTEBGdhZ6zuMLbqxidyqoKe2ygdMhVwsYUdQUqkMatHgf'),
                ),
              ),
              const Divider(height: 0),
              AquaListItem(
                colors: aquaColors,
                title: loc.boltzTotalFees,
                titleColor: aquaColors.textPrimary,
                titleTrailing: '\$3.48',
                titleTrailingColor: aquaColors.textPrimary,
                subtitleTrailing: '0.0000612 BTC',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AquaText.body1SemiBold(
                text: '$_getNameOfAltAsset Swap Details',
                color: aquaColors.textPrimary,
              ),
              AquaIcon.infoCircle(
                color: aquaColors.textPrimary,
              ),
            ],
          ),
        ),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                colors: aquaColors,
                title: loc.provider,
                titleColor: aquaColors.textPrimary,
                subtitleTrailing: 'SideShift',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
              const Divider(height: 0),
              AquaListItem(
                colors: aquaColors,
                title: 'SideShift ID',
                titleColor: aquaColors.textPrimary,
                subtitle: 'TYseuBSHmwzgHthcr18y5a5N8jsYsa4t3H',
                subtitleColor: aquaColors.textSecondary,
                iconTrailing: AquaIcon.copy(
                  color: aquaColors.textSecondary,
                  size: 18,
                ),
                onTap: () => context
                    .copyToClipboard('TYseuBSHmwzgHthcr18y5a5N8jsYsa4t3H'),
              ),
              const Divider(height: 0),
              AquaListItem(
                colors: aquaColors,
                title: loc.boltzServiceFee,
                titleColor: aquaColors.textPrimary,
                subtitleTrailing: '0.9%',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AquaFeeTile(
                  icon: AquaAssetIcon.fromAssetId(
                    assetId: AssetIds.lbtc.first,
                    size: 18,
                  ),
                  title: 'L-BTC',
                  amountCrypto: '25 Sat/vB',
                  amountFiat: '≈ \$1.9662',
                  isSelected: selectedFeeTile.value == 0,
                  colors: aquaColors,
                  isEnabled: true,
                  onTap: () {
                    selectedFeeTile.value = 0;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AquaFeeTile(
                  icon: AquaAssetIcon.fromAssetId(
                    assetId: AssetIds.usdtTether,
                    size: 18,
                  ),
                  title: 'USDt',
                  amountCrypto: '25 Sat/vB',
                  amountFiat: '≈ \$1.9662',
                  isSelected: selectedFeeTile.value == 1,
                  colors: aquaColors,
                  isEnabled: true,
                  onTap: () {
                    selectedFeeTile.value = 1;
                  },
                ),
              ),
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
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: SendConfirmAltUsdtSideSheet(
        aquaColors: aquaColors,
        loc: loc,
        assetId: assetId,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

String _getAssetTicker(String assetId) => switch (assetId) {
      AssetIds.btc => 'BTC',
      _ when (AssetIds.lbtc.contains(assetId)) => 'L-BTC',
      _ when (AssetIds.isAnyUsdt(assetId)) => 'USDt',
      AssetIds.lightning => 'Lightning',
      _ => throw UnimplementedError(),
    };
