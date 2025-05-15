import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/keys/wallet_keys.dart';
import 'package:aqua/utils/utils.dart';

import '../../scan/scan.dart';
import '../../text_scan/text_scan.dart';

///
class WalletExchangeButtonsPanel extends ConsumerWidget {
  const WalletExchangeButtonsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 59.0,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 1.5,
            color: context.colors.walletHeaderDivider,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          //ANCHOR - Receive Button
          Expanded(
            child: _Button(
              key: WalletKeys.homeReceiveButton,
              spacing: 8.0,
              label: context.loc.receive,
              svgAsset: UiAssets.svgs.walletHeaderReceive,
              padding: const EdgeInsetsDirectional.only(start: 2.0),
              radius: const BorderRadius.only(bottomLeft: Radius.circular(9.0)),
              onPressed: () => context.push(
                TransactionMenuScreen.routeName,
                extra: TransactionType.receive,
              ),
            ),
          ),
          VerticalDivider(
            thickness: 1.5,
            width: 1.5,
            color: context.colors.walletHeaderDivider,
          ),
          //ANCHOR - Send Button
          Expanded(
            child: _Button(
              key: WalletKeys.homeSendButton,
              spacing: 8.0,
              label: context.loc.send,
              svgAsset: UiAssets.svgs.walletHeaderSend,
              padding: const EdgeInsetsDirectional.only(end: 4.0),
              onPressed: () => context.push(
                TransactionMenuScreen.routeName,
                extra: TransactionType.send,
              ),
            ),
          ),
          VerticalDivider(
            thickness: 1.5,
            width: 1.5,
            color: context.colors.walletHeaderDivider,
          ),
          //ANCHOR - Scan Button
          Expanded(
            child: _Button(
              key: WalletKeys.homeScanButton,
              spacing: 12.0,
              padding: const EdgeInsetsDirectional.only(end: 6.0),
              svgAsset: UiAssets.svgs.walletHeaderScan,
              label: context.loc.scan,
              radius:
                  const BorderRadius.only(bottomRight: Radius.circular(9.0)),
              onPressed: () => context.push(
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    super.key,
    required this.svgAsset,
    required this.label,
    required this.spacing,
    required this.onPressed,
    this.radius,
    this.padding = EdgeInsets.zero,
  });

  final SvgGenImage svgAsset;
  final String label;
  final double spacing;
  final VoidCallback onPressed;
  final BorderRadius? radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.maxFinite,
      child: Material(
        borderRadius: radius,
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          splashColor: context.colors.walletTabButtonBackgroundColor,
          borderRadius: radius,
          child: Ink(
            child: Container(
              padding: padding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //ANCHOR - Icon
                  svgAsset.svg(
                    width: 12.0,
                    height: 12.0,
                    fit: BoxFit.scaleDown,
                    colorFilter: ColorFilter.mode(
                      context.colorScheme.onPrimaryContainer,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: spacing),
                  //ANCHOR - Label
                  Container(
                    margin: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
