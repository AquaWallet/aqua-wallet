import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/utils/utils.dart';

MarketplaceService buildSwapsService({
  required BuildContext context,
}) {
  return MarketplaceService(
    title: context.loc.swaps,
    subtitle: context.loc.marketplaceScreenExchangeButtonDescription,
    icon: Svgs.marketplaceExchange,
    onPressed: () => context.push(SwapScreen.routeName),
  );
}
