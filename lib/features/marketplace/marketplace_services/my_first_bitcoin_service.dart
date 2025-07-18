import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/features/marketplace/models/market_place_service.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:aqua/utils/utils.dart';

MarketplaceService buildMyFirstBitcoinService({
  required BuildContext context,
}) {
  return MarketplaceService(
    title: context.loc.marketplaceScreenMyFirstBitcoinButton,
    subtitle: context.loc.marketplaceScreenMyFirstBitcoinButton,
    icon: Svgs.website,
    onPressed: () => context.push(
      WebviewScreen.routeName,
      extra: WebviewArguments(
        Uri.parse(swapsService),
        context.loc.marketplaceScreenMyFirstBitcoinButton,
      ),
    ),
  );
}
