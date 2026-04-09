import 'package:aqua/features/marketplace/widgets/marketplace_tile.dart';
import 'package:aqua/features/shared/shared.dart';

class GiftCardTile extends StatelessWidget {
  const GiftCardTile({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketplaceTile(
      title: 'context.loc.marketplaceScreenGiftCards',
      subtitle: 'context.loc.marketplaceScreenGiftCardsDescription',
      icon: UiAssets.tabWallet.path,
      onPressed: () => context.push('GiftCardScreen.routeName'),
    );
  }
}
