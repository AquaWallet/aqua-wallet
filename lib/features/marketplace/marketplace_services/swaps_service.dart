import 'package:coin_cz/config/constants/svgs.dart';
import 'package:coin_cz/features/marketplace/marketplace.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/utils/utils.dart';

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
