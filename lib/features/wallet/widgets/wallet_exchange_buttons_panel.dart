import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/screens/qrscanner/qr_scanner_screen.dart';
import 'package:aqua/utils/utils.dart';

class WalletExchangeButtonsPanel extends ConsumerWidget {
  const WalletExchangeButtonsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 57.h,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 1.5.w,
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
              spacing: 8.w,
              label: context.loc.receive,
              svgAsset: UiAssets.svgs.walletHeaderReceive,
              padding: EdgeInsetsDirectional.only(start: 2.w),
              radius: BorderRadius.only(bottomLeft: Radius.circular(9.r)),
              onPressed: () => Navigator.of(context).pushNamed(
                TransactionMenuScreen.routeName,
                arguments: TransactionType.receive,
              ),
            ),
          ),
          VerticalDivider(
            thickness: 1.5.w,
            width: 1.5.w,
            color: context.colors.walletHeaderDivider,
          ),
          //ANCHOR - Send Button
          Expanded(
            child: _Button(
              spacing: 8.w,
              label: context.loc.send,
              svgAsset: UiAssets.svgs.walletHeaderSend,
              padding: EdgeInsetsDirectional.only(end: 4.w),
              onPressed: () => Navigator.of(context).pushNamed(
                TransactionMenuScreen.routeName,
                arguments: TransactionType.send,
              ),
            ),
          ),
          VerticalDivider(
            thickness: 1.5.w,
            width: 1.5.w,
            color: context.colors.walletHeaderDivider,
          ),
          //ANCHOR - Scan Button
          Expanded(
            child: _Button(
              spacing: 12.w,
              padding: EdgeInsetsDirectional.only(end: 6.w),
              svgAsset: UiAssets.svgs.walletHeaderScan,
              label: context.loc.scan,
              radius: BorderRadius.only(bottomRight: Radius.circular(9.r)),
              onPressed: () => Navigator.of(context).pushNamed(
                QrScannerScreen.routeName,
                arguments: QrScannerScreenArguments(
                  parseAction: QrScannerParseAction.parse,
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
                    width: 12.r,
                    height: 12.r,
                    fit: BoxFit.scaleDown,
                    colorFilter: ColorFilter.mode(
                      context.colorScheme.onPrimaryContainer,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: spacing),
                  //ANCHOR - Label
                  Container(
                    margin: EdgeInsets.only(top: 2.h),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.sp,
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
