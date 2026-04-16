import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/features/marketplace/widgets/marketplace_tile.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChapsmartTile extends StatelessWidget {
  const ChapsmartTile({super.key});

  @override
  Widget build(BuildContext context) => MarketplaceTile(
        title: context.loc.marketplaceScreenChapsmartButton,
        subtitle: context.loc.marketplaceScreenChapsmartButtonDescription,
        iconBuilder: ({color, required size}) => SvgPicture.asset(
          UiAssets.marketplace.chapsmart.path,
          height: size,
          width: size,
          fit: BoxFit.scaleDown,
        ),
        onPressed: () => context.push(
          WebviewScreen.routeName,
          extra: WebviewArguments(
            Uri.parse(chapsmartUrl),
            context.loc.marketplaceScreenChapsmartButton,
          ),
        ),
      );
}
