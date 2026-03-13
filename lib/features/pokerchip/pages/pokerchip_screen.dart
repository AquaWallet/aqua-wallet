import 'package:aqua/features/pokerchip/pokerchip.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class PokerchipScreen extends HookConsumerWidget {
  const PokerchipScreen({super.key});

  static const routeName = '/pokerchipScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        title: context.loc.bitcoinChip,
        colors: context.aquaColors,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AquaCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                title: context.loc.scanBitcoinChip,
                subtitle: context.loc.bitcoinChipScanBitcoinChipSubtitle,
                subtitleColor: context.aquaColors.textSecondary,
                iconLeading: AquaIcon.pokerchip(
                  color: context.aquaColors.textSecondary,
                  size: 24,
                ),
                iconTrailing: AquaIcon.chevronForward(
                  color: context.aquaColors.textSecondary,
                  size: 18,
                ),
                onTap: () => context.push(PokerchipScannerScreen.routeName),
              ),
              // TODO: This is present in the design but not implemented yet.
              // AquaListItem(
              //   title: context.loc.bitcoinChipLoadBitcoinChip,
              //   subtitle: context.loc.bitcoinChipLoadBitcoinChipSubtitle,
              //   subtitleColor: context.aquaColors.textSecondary,
              //   iconLeading: AquaIcon.upload(
              //     color: context.aquaColors.textSecondary,
              //     size: 24,
              //   ),
              //   iconTrailing: AquaIcon.chevronForward(
              //     color: context.aquaColors.textSecondary,
              //     size: 18,
              //   ),
              //   onTap: () {},
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
