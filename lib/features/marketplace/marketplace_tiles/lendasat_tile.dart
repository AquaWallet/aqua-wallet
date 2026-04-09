import 'package:aqua/features/lending/pages/loans_listings_screen.dart';
import 'package:aqua/features/marketplace/widgets/marketplace_tile.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class LendasatTile extends StatelessWidget {
  const LendasatTile({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketplaceTile(
      title: context.loc.marketplaceScreenLendasatButton,
      subtitle: context.loc.marketplaceScreenLendasatButtonDescription,
      icon: UiAssets.walletSend.path,
      onPressed: () => context.push(
        LoansListingsScreen.routeName,
      ),
    );
  }
}
