import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ui_components/ui_components.dart';

class ScanBitcoinChipSideSheetWidget extends StatelessWidget {
  const ScanBitcoinChipSideSheetWidget({
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
      title: loc.scanBitcoinChip,
      showBackButton: false,
      widgetAtBottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlineContainer(
            aquaColors: aquaColors,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AquaListItem(
                  colors: aquaColors,
                  title: 'Load Bitcoin Chip',
                  titleColor: aquaColors.textPrimary,
                  contentWidget: AquaColoredText(
                    text:
                        'bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297',
                    style: AquaAddressTypography.body2.copyWith(
                      color: aquaColors.textSecondary,
                    ),
                    colorType: ColoredTextEnum.coloredIntegers,
                  ),
                  iconTrailing: AquaIcon.copy(color: aquaColors.textSecondary),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AquaButton.primary(
            text: loc.next,
            onPressed: () => BitcoinChipSideSheetWidget.show(
              context: context,
              aquaColors: aquaColors,
              loc: loc,
            ),
          ),
        ],
      ),
      children: [
        ///TODO: replace with appropriate widget for scanning
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: aquaColors.surfacePrimary,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: AquaText.body1Medium(
              text: 'Load scan with camera',
              color: aquaColors.textSecondary,
              textAlign: TextAlign.center,
            ),
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
      body: ScanBitcoinChipSideSheetWidget(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class BitcoinChipSideSheetWidget extends StatelessWidget {
  const BitcoinChipSideSheetWidget({
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
      title: loc.bitcoinChip,
      onBackPress: () {
        Navigator.pop(context);
        ScanBitcoinChipSideSheetWidget.show(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
        );
      },
      widgetAtBottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          AquaButton.primary(
            text: loc.bitcoinChipSweepToWallet,
            onPressed: () => ConfirmSweepBitcoinScanSideSheetWidget.show(
              context: context,
              aquaColors: aquaColors,
              loc: loc,
            ),
          ),
          const SizedBox(height: 16),
          AquaButton.secondary(
            text: loc.close,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      children: [
        ///TODO: replace with appropriate widget for scanning
        SizedBox.square(
          dimension: 160.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                Svgs.pokerchipFrameLight,
                width: 160.0,
                height: 160.0,
                colorFilter: ColorFilter.mode(
                  aquaColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
              AquaAssetIcon.fromAssetId(
                assetId: AssetIds.btc,
                size: 48,
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
                colors: aquaColors,
                title: loc.balance,
                titleColor: aquaColors.textPrimary,
                iconLeading: AquaAssetIcon.fromAssetId(
                  assetId: AssetIds.btc,
                  size: 24,
                ),
                titleTrailing: '0.0000345 BTC',
                titleTrailingColor: aquaColors.textPrimary,
                subtitleTrailing: '\$1.23',
                subtitleTrailingColor: aquaColors.textSecondary,
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
      body: BitcoinChipSideSheetWidget(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class ConfirmSweepBitcoinScanSideSheetWidget extends HookWidget {
  const ConfirmSweepBitcoinScanSideSheetWidget({
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

    const isSuccess = false;
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.bitcoinChipConfirmSweep,
      showBackButton: false,
      widgetAtBottom: AquaSlider(
        key: enabledSliderKey.value,
        colors: aquaColors,
        text: 'Slide',
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
        AquaTransactionSummary.receive(
          isPending: false,
          colors: context.aquaColors,
          assetId: AssetIds.btc,
          assetTicker: 'BTC',
          amountCrypto: '-0.04738384',
          amountFiat: '-\$4,558.51',
        ),
        const SizedBox(height: 24),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                colors: aquaColors,
                title: 'Recipient',
                titleColor: aquaColors.textPrimary,
                iconLeading: AquaIcon.wallet(color: aquaColors.textPrimary),
                titleTrailing: 'Wallet name',
                titleTrailingColor: aquaColors.textPrimary,
                subtitleTrailing: 'B89AB7BC',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
              const Divider(height: 0),
              AquaListItem(
                colors: aquaColors,
                title: 'Add Note',
                titleColor: aquaColors.textPrimary,
                iconLeading: AquaIcon.edit(color: aquaColors.textPrimary),
                iconTrailing:
                    AquaIcon.chevronRight(color: aquaColors.textSecondary),
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
      body: ConfirmSweepBitcoinScanSideSheetWidget(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
