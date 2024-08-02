import 'package:aqua/config/config.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/screens/qrscanner/qr_scanner_screen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

class TransactionMenuBottomBar extends HookConsumerWidget {
  const TransactionMenuBottomBar({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lightningAsset = ref
        .watch(manageAssetsProvider.select((p) => p.curatedAssets))
        .firstWhere((lightningAsset) => lightningAsset.isLightning);

    return SizedBox(
      height: 64.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          //ANCHOR - Receive Button
          Expanded(
            child: _MenuButton(
              svgAssetName: Svgs.walletReceive,
              radius: BorderRadius.only(bottomLeft: Radius.circular(20.r)),
              label: context.loc.receive,
              onPressed: () => Navigator.of(context).pushNamed(
                ReceiveAssetScreen.routeName,
                arguments: asset.isLBTC ? lightningAsset : asset,
              ),
            ),
          ),
          //ANCHOR - Send Button
          Expanded(
            child: _MenuButton(
              svgAssetName: Svgs.walletSend,
              label: context.loc.send,
              onPressed: () => {
                ref
                    .read(sendNavigationEntryProvider(
                        SendAssetArguments.fromAsset(asset)))
                    .call(context)
              },
            ),
          ),
          //ANCHOR - Scan Button
          Expanded(
            child: _MenuButton(
              svgAssetName: Svgs.walletScan,
              label: context.loc.scan,
              radius: BorderRadius.only(bottomRight: Radius.circular(20.r)),
              onPressed: () => {
                Navigator.of(context).pushNamed(
                  QrScannerScreen.routeName,
                  arguments: QrScannerScreenArguments(
                    asset: asset,
                    parseAction: QrScannerParseAction.parse,
                  ),
                )
                // }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.svgAssetName,
    required this.label,
    this.radius,
    required this.onPressed,
  });

  final BorderRadius? radius;
  final String svgAssetName;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.maxFinite,
      child: Material(
        borderRadius: radius,
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Ink(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //ANCHOR - Icon
                SvgPicture.asset(svgAssetName,
                    width: 16.w,
                    height: 16.w,
                    fit: BoxFit.scaleDown,
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onBackground,
                        BlendMode.srcIn)),
                SizedBox(height: 12.h),
                //ANCHOR - Label
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
