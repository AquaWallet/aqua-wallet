import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/features/marketplace/widgets/marketplace_button.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:aqua/utils/utils.dart';

class BtcMapTile extends StatelessWidget {
  const BtcMapTile({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketplaceButton(
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
}
