import 'package:coin_cz/config/constants/svgs.dart';
import 'package:coin_cz/config/constants/urls.dart';
import 'package:coin_cz/features/marketplace/models/market_place_service.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/screens/common/webview_screen.dart';
import 'package:coin_cz/utils/utils.dart';

MarketplaceService buildBtcMapService({
  required BuildContext context,
}) {
  return MarketplaceService(
    title: context.loc.marketplaceScreenBtcMapButton,
    subtitle: context.loc.marketplaceScreenBtcMapButtonDescription,
    icon: Svgs.mapIcon,
    onPressed: () => context.push(
      WebviewScreen.routeName,
      extra: WebviewArguments(
        Uri.parse(btcMapUrl),
        context.loc.marketplaceScreenBtcMapButton,
      ),
    ),
  );
}
