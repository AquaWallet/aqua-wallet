import 'dart:async';

import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/shared/utils/transaction_item_localizations_extension.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class LoadBitcoinChipSideSheetWidget extends HookWidget {
  const LoadBitcoinChipSideSheetWidget({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    final selectedTab = useState(LoadBitcoinChipTabBar.csv);
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.bitcoinChipAddChipAddresses,
      showBackButton: false,
      widgetAtBottom: AquaButton.primary(
        text: loc.bitcoinChipParseAddresses,
        onPressed: () => ChooseDenominationChipSideSheetWidget.show(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
        ),
      ),
      children: [
        LinearStepAnimatedProgress(
          aquaColors: aquaColors,
          numberOfSteps: 4,
          numberOfStepsToLoad: 1,
        ),
        const SizedBox(height: 24),
        AquaText.body1SemiBold(
          text: loc.bitcoinChipUploadACsvOrEnterAddresses,
          color: aquaColors.textPrimary,
        ),
        const SizedBox(height: 8),
        AquaText.body2(
          text:
              'Must include an Address column. Optional columns: Amount (in sats), Asset (hex asset ID), and Label.',
          color: aquaColors.textSecondary,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                colors: aquaColors,
                title: 'Bitcoin',
                titleColor: aquaColors.textPrimary,
                iconLeading: AquaAssetIcon.fromAssetId(
                  assetId: AssetIds.btc,
                  size: 40,
                ),
                iconTrailing: AquaRadio<bool>.small(
                  value: true,
                  groupValue: true,
                  colors: context.aquaColors,
                ),
                onTap: () {},
              ),
              AquaListItem(
                colors: aquaColors,
                title: 'L-USDt',
                titleColor: aquaColors.textPrimary,
                iconLeading: AquaAssetIcon.fromAssetId(
                  assetId: AssetIds.usdtTether,
                  size: 40,
                ),
                iconTrailing: AquaRadio<bool>.small(
                  value: false,
                  groupValue: true,
                  colors: context.aquaColors,
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AquaTabBar(
          tabs: const ['CSV', 'Manual'],
          selectedColor: aquaColors.surfacePrimary,
          onTabChanged: (value) {
            selectedTab.value = LoadBitcoinChipTabBar.values[value];
          },
        ),
        const SizedBox(height: 16),
        switch (selectedTab.value) {
          LoadBitcoinChipTabBar.csv => SizedBox(
              height: 150,
              child: DottedBorder(
                color: aquaColors.accentBrand,
                strokeWidth: 1,
                dashPattern: const [4.0, 2.0],
                borderType: BorderType.RRect,
                radius: const Radius.circular(16),
                child: Container(
                  width: double.maxFinite,
                  color: aquaColors.surfaceSelected,
                  constraints: const BoxConstraints(
                    minHeight: minHeightForCsvLoadTabBar,
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //TODO: missing Step/Folder image from codebase
                        const SizedBox(height: 16),
                        AquaText.body1SemiBold(
                          text: loc.bitcoinChipUploadFile,
                          color: aquaColors.textPrimary,
                        ),
                        const SizedBox(height: 8),
                        AquaText.body2(
                          text: loc.bitcoinChipCsvLessThan5mb,
                          color: aquaColors.textSecondary,
                          maxLines: 3,
                        ),
                      ]),
                ),
              ),
            ),
          LoadBitcoinChipTabBar.manual => Column(
              children: [
                const AquaTextField(
                  label: 'Paste addresses, one per line.',
                  error: false,
                  forceFocus: false,
                  enabled: true,
                  minLines: 5,
                  maxLines: 5 + 2,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AquaButton.utility(
                        text: loc.scan,
                        icon: AquaIcon.scan(
                          color: aquaColors.textPrimary,
                        ),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: AquaButton.utility(
                        text: 'Paste',
                        icon: AquaIcon.paste(
                          color: aquaColors.textPrimary,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                )
              ],
            ),
        }
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    return SideSheet.right(
      body: LoadBitcoinChipSideSheetWidget(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class ChooseDenominationChipSideSheetWidget extends HookWidget {
  const ChooseDenominationChipSideSheetWidget({
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
      title: loc.bitcoinChipChooseDenomination,
      showBackButton: true,
      onBackPress: () {
        Navigator.pop(context);
        LoadBitcoinChipSideSheetWidget.show(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
        );
      },
      children: [
        LinearStepAnimatedProgress(
          aquaColors: aquaColors,
          numberOfSteps: 4,
          numberOfStepsToLoad: 2,
        ),
        const SizedBox(height: 24),
        OutlineContainer(
          aquaColors: aquaColors,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: denominationBtc.length,
            separatorBuilder: (context, index) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final denomination = denominationBtc[index];
              return AquaListItem(
                colors: aquaColors,
                title: denomination.amount,
                titleColor: aquaColors.textPrimary,
                iconLeading: AquaIcon.pokerchip(
                  color: denomination.color,
                ),
                iconTrailing: AquaIcon.chevronRight(
                  color: aquaColors.textSecondary,
                ),
                onTap: () => ConfirmSweepChipEditSideSheetWidget.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                ),
              );
            },
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
    Navigator.pop(context);
    return SideSheet.right(
      body: ChooseDenominationChipSideSheetWidget(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class ConfirmSweepChipEditSideSheetWidget extends HookWidget {
  const ConfirmSweepChipEditSideSheetWidget({
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
      title: loc.bitcoinChipConfirmSweep,
      showBackButton: true,
      onBackPress: () => ChooseDenominationChipSideSheetWidget.show(
        context: context,
        aquaColors: aquaColors,
        loc: loc,
      ),
      widgetAtBottom: AquaButton.primary(
        text: loc.next,
        onPressed: () => ConfirmSweepChipSideSheetWidget.show(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
        ),
      ),
      children: [
        LinearStepAnimatedProgress(
          aquaColors: aquaColors,
          numberOfSteps: 4,
          numberOfStepsToLoad: 3,
        ),
        const SizedBox(height: 24),
        OutlineContainer(
          aquaColors: aquaColors,
          child: AquaListItem(
            colors: aquaColors,
            title: loc.bitcoinChipDefaultAmount,
            titleColor: aquaColors.textPrimary,
            iconTrailing: AquaIcon.edit(
              color: aquaColors.textSecondary,
            ),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 24),
        ListView.separated(
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return OutlineContainer(
              aquaColors: aquaColors,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AquaListItem(
                    colors: aquaColors,
                    title: 'Chip $index',
                    titleColor: aquaColors.textPrimary,
                    iconLeading: AquaIcon.pokerchip(
                      color: aquaColors.accentBrand,
                    ),
                    titleTrailing: '0.0001 BTC',
                    titleTrailingColor: aquaColors.textSecondary,
                    iconTrailing: AquaIcon.edit(
                      color: aquaColors.textSecondary,
                      size: 18,
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 0),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: AquaColoredText(
                            text:
                                'VJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVq',
                            style: AquaAddressTypography.body2.copyWith(
                              color: aquaColors.textPrimary,
                            ),
                            colorType: ColoredTextEnum.coloredIntegers,
                          ),
                        ),
                        const SizedBox(width: 16),
                        AquaIcon.copy(
                          size: 18,
                          color: aquaColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemCount: 4,
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: ConfirmSweepChipEditSideSheetWidget(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class ConfirmSweepChipSideSheetWidget extends HookWidget {
  const ConfirmSweepChipSideSheetWidget({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    final enabledSliderKey = useState(UniqueKey());
    final sliderState = useState(AquaSliderState.initial);

    const isSuccess = true;

    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.bitcoinChipConfirmSweep,
      showBackButton: true,
      onBackPress: () => ConfirmSweepChipEditSideSheetWidget.show(
        context: context,
        aquaColors: aquaColors,
        loc: loc,
      ),
      widgetAtBottom: AquaSlider(
        key: enabledSliderKey.value,
        colors: aquaColors,
        text: loc.confirmChipLoadSlideToLoad,
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
          ModelSheetFunctionsForSweep.showModelSheet(
            context: context,
            aquaColors: aquaColors,
            loc: loc,
            isSuccess: isSuccess,
          );
        },
      ),
      children: [
        LinearStepAnimatedProgress(
          aquaColors: aquaColors,
          numberOfSteps: 4,
          numberOfStepsToLoad: 4,
        ),
        const SizedBox(height: 24),
        AquaTransactionItem.send(
          isPending: false,
          isFailed: false,
          colors: context.aquaColors,
          iconAssetId: AssetIds.btc,
          timestamp: tempDate,
          text: loc.transactionItemLocalizations,
          amountCrypto: '-0.04738384',
          amountFiat: '-\$4,558.51',
        ),
        const SizedBox(height: 16),
        AquaText.body1SemiBold(
          text: 'Recipient',
          color: aquaColors.textPrimary,
        ),
        const SizedBox(height: 16),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            children: [
              AquaListItem(
                colors: aquaColors,
                title: '25 x Chip Load',
                titleColor: aquaColors.textPrimary,
                iconLeading: AquaIcon.pokerchip(
                  color: aquaColors.textPrimary,
                ),
                subtitleTrailing: '0.0001 BTC',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
              const Divider(height: 0),
              AquaListItem(
                colors: aquaColors,
                title: 'Chip Load',
                titleColor: aquaColors.textPrimary,
                iconLeading: AquaIcon.pokerchip(
                  color: aquaColors.textPrimary,
                ),
                titleTrailing: '20 Chips',
                titleTrailingColor: aquaColors.textPrimary,
                subtitleTrailing: 'x0.02 BTC',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
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
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: ConfirmSweepChipSideSheetWidget(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
