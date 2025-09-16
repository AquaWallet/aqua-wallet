import 'package:coin_cz/config/constants/svgs.dart';
import 'package:coin_cz/features/marketplace/models/market_place_service.dart';
import 'package:coin_cz/features/private_integrations/debit_card/debit_card.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

MarketplaceService buildDebitCardService({
  required BuildContext context,
}) {
  return MarketplaceService(
    title: context.loc.marketplaceScreenDolphinCardButton,
    subtitle: context.loc.marketplaceScreenDolphinCardButtonDescription,
    icon: Svgs.marketplaceBankings,
    onPressed: () => context.push(
      DebitCardMyCardScreen.routeName,
    ),
  );
}
