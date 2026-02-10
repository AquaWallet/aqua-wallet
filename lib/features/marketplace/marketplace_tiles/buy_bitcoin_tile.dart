import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/marketplace/widgets/marketplace_tile.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class BuyBitcoinTile extends StatelessWidget {
  const BuyBitcoinTile({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketplaceTile(
      title: context.loc.marketplaceScreenBuyButton,
      subtitle: context.loc.marketplaceScreenBuyButtonDescription,
      iconBuilder: ({color, required size}) => AquaIcon.plus(
        color: color,
        size: size,
      ),
      onPressed: () => context.push(OnRampScreen.routeName),
    );
  }
}
