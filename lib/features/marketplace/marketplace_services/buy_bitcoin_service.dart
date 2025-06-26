// buy_bitcoin_service.dart
import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

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
