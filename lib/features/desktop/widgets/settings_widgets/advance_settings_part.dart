import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AdvancedSettings extends HookWidget {
  const AdvancedSettings({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    final toggle = useState(false);
    return OutlineContainer(
      aquaColors: aquaColors,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AquaListItem(
            colors: aquaColors,
            iconLeading: AquaIcon.eyeOpen(color: aquaColors.textPrimary),
            title: 'Export Watch Only Wallet',
            titleColor: aquaColors.textPrimary,
            iconTrailing:
                AquaIcon.chevronRight(color: aquaColors.textSecondary),
            onTap: () {
              SideSheet.right(
                colors: aquaColors,
                context: context,
                body: ExportWatchOnlySideSheetWidget(
                  aquaColors: aquaColors,
                  loc: loc,
                ),
              );
            },
          ),
          const Divider(height: 0),
          AquaListItem(
            colors: aquaColors,
            iconLeading: AquaIcon.pegIn(color: aquaColors.textPrimary),
            title: loc.directPegIn,
            titleColor: aquaColors.textPrimary,
            iconTrailing: AquaToggle(
              value: toggle.value,
              onChanged: (value) => toggle.value = value,
            ),
            onTap: () {
              ///TODO: implement on click
            },
          ),
          const Divider(height: 0),
          AquaListItem(
            colors: aquaColors,
            iconLeading: AquaIcon.pokerchip(color: aquaColors.textPrimary),
            title: loc.bitcoinChip,
            titleColor: aquaColors.textPrimary,
            iconTrailing:
                AquaIcon.chevronRight(color: aquaColors.textSecondary),
            onTap: () {
              ///TODO: implement on click
            },
          ),
          const Divider(height: 0),
          AquaListItem(
            colors: aquaColors,
            iconLeading: AquaIcon.btcpay(color: aquaColors.textPrimary),
            title: 'BTCPay Server',
            titleColor: aquaColors.textPrimary,
            iconTrailing:
                AquaIcon.chevronRight(color: aquaColors.textSecondary),
            onTap: () {
              ///TODO: implement on click
            },
          ),
          const Divider(height: 0),
          AquaListItem(
            colors: aquaColors,
            iconLeading: AquaIcon.export(color: aquaColors.textPrimary),
            title: 'Export & Share Logs',
            titleColor: aquaColors.textPrimary,
            iconTrailing:
                AquaIcon.chevronRight(color: aquaColors.textSecondary),
            onTap: () {
              ///TODO: implement on click
            },
          ),
          const Divider(height: 0),
          AquaListItem(
            colors: aquaColors,
            iconLeading: AquaIcon.experimental(color: aquaColors.textPrimary),
            title: 'Experimental',
            titleColor: aquaColors.textPrimary,
            iconTrailing:
                AquaIcon.chevronRight(color: aquaColors.textSecondary),
            onTap: () {
              ///TODO: implement on click
            },
          ),
          const Divider(height: 0),
          AquaListItem(
            colors: aquaColors,
            iconLeading: AquaIcon.danger(color: aquaColors.accentDanger),
            title: 'Remove Wallet',
            titleColor: aquaColors.accentDanger,
            iconTrailing: AquaIcon.chevronRight(color: aquaColors.accentDanger),
            onTap: () {
              ///TODO: implement on click
            },
          ),
        ],
      ),
    );
  }
}

class ExportWatchOnlySideSheetWidget extends HookWidget {
  const ExportWatchOnlySideSheetWidget({
    super.key,
    required this.aquaColors,
    required this.loc,
  });

  final AquaColors aquaColors;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final selectedTab = useState(ExportWatchOnlyTabBarValues.bitcoin);
    const mockBitcoinCode =
        'bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297';
    const mockLiquidCode =
        'VJLEERnmhwXPBP9BEH9xUfg7TYxDiXaZavjydBptPDqQiEUZvipYmggVcJdL8qUKqpy91wxUxZiGruR2';

    final mockCode =
        selectedTab.value.isBitcoin ? mockBitcoinCode : mockLiquidCode;

    final assetId =
        selectedTab.value.isBitcoin ? AssetIds.btc : AssetIds.lbtc.first;

    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.warningPhraseScreenTitle,
      showBackButton: false,
      widgetAtBottom: AquaButton.primary(
        text: 'Export Watch Only',
        icon: AquaIcon.copy(
          color: aquaColors.textInverse,
          // size: 16,
        ),
        onPressed: () {
          context.copyToClipboard(mockCode);
        },
      ),
      children: [
        AquaTabBar(
          height: 36,
          tabs: [loc.internalSendReviewBitcoin, loc.liquid],
          selectedColor: aquaColors.surfacePrimary,
          onTabChanged: (index) {
            index == 0
                ? selectedTab.value = ExportWatchOnlyTabBarValues.bitcoin
                : selectedTab.value = ExportWatchOnlyTabBarValues.liquid;
          },
        ),

        ///TODO: show diffrent content for selected tabs
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaChip.accent(
                label: selectedTab.value.isBitcoin
                    ? 'Bitcoin Watch Only Wallet'
                    : 'Liquid Watch Only Wallet',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: AquaAssetQRCode(
                  content: mockCode,
                  assetId: assetId,
                ),
              ),
              AquaColoredText(
                text: mockCode,
                style: AquaAddressTypography.body2.copyWith(
                  color: aquaColors.textSecondary,
                ),
                colorType: ColoredTextEnum.coloredIntegers,
              )
            ],
          ),
        ),
      ],
    );
  }
}
