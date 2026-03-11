import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/features/marketplace/widgets/marketplace_tile.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class BtcMapTile extends StatelessWidget {
  const BtcMapTile({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketplaceTile(
      title: context.loc.marketplaceScreenBtcMapButton,
      subtitle: context.loc.marketplaceScreenBtcMapButtonDescription,
      iconBuilder: ({color, required size}) => AquaIcon.map(
        color: color,
        size: size,
      ),
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
