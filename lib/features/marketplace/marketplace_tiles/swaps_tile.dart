import 'package:aqua/features/marketplace/widgets/marketplace_tile.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class SwapsTile extends StatelessWidget {
  const SwapsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketplaceTile(
      title: context.loc.swaps,
      subtitle: context.loc.marketplaceScreenExchangeButtonDescription,
      iconBuilder: ({color, required size}) => AquaIcon.swap(
        color: color,
        size: size,
      ),
      onPressed: () => context.push(SwapScreen.routeName),
    );
  }
}
