import 'package:aqua/features/depix/depix.dart';
import 'package:aqua/features/marketplace/widgets/marketplace_tile.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class TopUpDepixTile extends StatelessWidget {
  const TopUpDepixTile({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketplaceTile(
      title: context.loc.marketplaceScreenTopUpDepixButton,
      subtitle: context.loc.marketplaceScreenTopUpDepixButtonDescription,
      iconBuilder: ({color, required size}) =>
          UiAssets.marketplace.dePixTile.svg(
        height: size,
        width: size,
        fit: BoxFit.scaleDown,
      ),
      isAuthRequired: true,
      onPressed: () => context.push(DepixScreen.routeName),
    );
  }
}
