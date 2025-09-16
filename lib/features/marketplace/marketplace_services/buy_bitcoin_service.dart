// buy_bitcoin_service.dart
import 'package:coin_cz/config/constants/svgs.dart';
import 'package:coin_cz/features/marketplace/marketplace.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

MarketplaceService buildBuyBitcoinService({
  required BuildContext context,
}) {
  return MarketplaceService(
    title: context.loc.marketplaceScreenBuyButton,
    subtitle: context.loc.marketplaceScreenBuyButtonDescription,
    icon: Svgs.marketplaceBuy,
    onPressed: () => context.push(OnRampScreen.routeName),
  );
}
