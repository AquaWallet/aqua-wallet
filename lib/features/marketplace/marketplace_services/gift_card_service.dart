import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/marketplace/models/market_place_service.dart';
import 'package:aqua/features/shared/shared.dart';
// import 'package:aqua/gift_cards/gift_card.dart';
// import 'package:aqua/utils/utils.dart';

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
