import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class BitcoinChipSettings extends StatelessWidget {
  const BitcoinChipSettings({
    super.key,
    required this.loc,
    required this.aquaColors,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                colors: aquaColors,
                iconLeading: AquaIcon.pokerchip(color: aquaColors.textPrimary),
                title: loc.scanBitcoinChip,
                titleColor: aquaColors.textPrimary,
                subtitle: loc.bitcoinChipScanBitcoinChipSubtitle,
                subtitleColor: aquaColors.textSecondary,
                iconTrailing:
                    AquaIcon.chevronRight(color: aquaColors.textSecondary),
                onTap: () => ScanBitcoinChipSideSheetWidget.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                ),
              ),
              const Divider(height: 0),
              AquaListItem(
                colors: aquaColors,
                iconLeading: AquaIcon.upload(color: aquaColors.textPrimary),
                title: 'Load Bitcoin Chip',
                titleColor: aquaColors.textPrimary,
                subtitle: loc.bitcoinChipLoadBitcoinChipSubtitle,
                subtitleColor: aquaColors.textSecondary,
                iconTrailing:
                    AquaIcon.chevronRight(color: aquaColors.textSecondary),
                onTap: () => LoadBitcoinChipSideSheetWidget.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
