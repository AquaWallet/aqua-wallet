import 'package:coin_cz/config/constants/svgs.dart';
import 'package:coin_cz/features/marketplace/models/market_place_service.dart';
import 'package:coin_cz/features/shared/shared.dart';
// import 'package:coin_cz/gift_cards/gift_card.dart';
// import 'package:coin_cz/utils/utils.dart';

MarketplaceService buildGiftCardsService({
  required BuildContext context,
}) {
  return MarketplaceService(
    title: 'context.loc.marketplaceScreenGiftCards',
    subtitle: 'context.loc.marketplaceScreenGiftCardsDescription',
    icon: Svgs.tabWallet,
    onPressed: () => context.push('GiftCardScreen.routeName'),
  );
}
