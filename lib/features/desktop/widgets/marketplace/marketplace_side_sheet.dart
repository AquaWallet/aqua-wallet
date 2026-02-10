import 'package:aqua/features/desktop/pages/pages.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class MarketPlaceSideSheet extends StatelessWidget {
  const MarketPlaceSideSheet({
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
      title: loc.marketplaceTitle,
      showBackButton: false,

      ///TODO: Replace with selected region from provider
      addIconNextToClose: Container(
        padding: const EdgeInsets.all(4),
        child: const AquaText.h4SemiBold(
          text: '🇳🇴',
        ),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: AquaMarketplaceTile(
                title: 'Buy & Sell',
                colors: aquaColors,
                subtitle: loc.marketplaceScreenBuyButtonDescription,
                icon: AquaIcon.plus(color: aquaColors.textPrimary),
                onTap: () {
                  Navigator.pop(context);
                  BuySellSideSheet.show(
                    context: context,
                    aquaColors: aquaColors,
                    loc: loc,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AquaMarketplaceTile(
                title: loc.swap,
                colors: aquaColors,
                subtitle: loc.marketplaceScreenExchangeButtonDescription,
                icon: AquaIcon.swap(color: aquaColors.textPrimary),
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AquaMarketplaceTile(
                colors: aquaColors,
                title: loc.marketplaceScreenBtcMapButton,
                subtitle: loc.marketplaceScreenBtcMapButtonDescription,
                icon: AquaIcon.map(color: aquaColors.textPrimary),
                onTap: () {
                  Navigator.pop(context);
                  context.go(MarketplaceMapScreen.routeName);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AquaMarketplaceTile(
                colors: aquaColors,
                title: loc.dolphinCard,
                subtitle: loc.marketplaceDolphinCardSubtitle,
                icon: AquaIcon.creditCard(color: aquaColors.textPrimary),
                onTap: () {
                  Navigator.pop(context);
                  DolphinCardSideSheet.show(
                    context: context,
                    aquaColors: aquaColors,
                    loc: loc,
                  );
                },
              ),
            ),
          ],
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
      body: MarketPlaceSideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
