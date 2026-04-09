import 'package:aqua/features/marketplace/widgets/marketplace_tile.dart';
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/scan/scan.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/text_scan/text_scan.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MoneyBadgerTile extends StatelessWidget {
  const MoneyBadgerTile({super.key});

  @override
  Widget build(BuildContext context) => MarketplaceTile(
        title: context.loc.marketplaceScreenMoneybadgerButton,
        subtitle: context.loc.marketplaceScreenMoneybadgerButtonDescription,
        iconBuilder: ({color, required size}) => SvgPicture.asset(
          UiAssets.marketplace.moneybadger.path,
          height: size,
          width: size,
          fit: BoxFit.scaleDown,
        ),
        onPressed: () async {
          final result = await context.push(
            ScanScreen.routeName,
            extra: ScanArguments(
              qrArguments: QrScannerArguments(
                parseAction: QrScannerParseAction.attemptToParse,
              ),
              textArguments: TextScannerArguments(
                parseAction: TextScannerParseAction.attemptToParse,
              ),
              initialType: ScannerType.qr,
            ),
          );
          if (result is QrScanState) {
            result.maybeWhen(
              sendAsset: (args) {
                context.push(SendAssetScreen.routeName, extra: args);
              },
              orElse: () {},
            );
          }
        },
      );
}
