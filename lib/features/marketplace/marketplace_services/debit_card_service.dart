import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/marketplace/models/market_place_service.dart';
import 'package:aqua/features/private_integrations/debit_card/debit_card.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

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
