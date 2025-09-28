import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/marketplace/widgets/marketplace_button.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class BuyBitcoinTile extends StatelessWidget {
  const BuyBitcoinTile({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketplaceButton(
      title: context.loc.marketplaceScreenBuyButton,
      subtitle: context.loc.marketplaceScreenBuyButtonDescription,
      icon: Svgs.marketplaceBuy,
      onPressed: () => context.push(OnRampScreen.routeName),
    );
  }
}
