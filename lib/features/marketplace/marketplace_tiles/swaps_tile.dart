import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/marketplace/widgets/marketplace_button.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/utils/utils.dart';

class SwapsTile extends StatelessWidget {
  const SwapsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketplaceButton(
      title: context.loc.swaps,
      subtitle: context.loc.marketplaceScreenExchangeButtonDescription,
      icon: Svgs.marketplaceExchange,
      onPressed: () => context.push(SwapScreen.routeName),
    );
  }
}
