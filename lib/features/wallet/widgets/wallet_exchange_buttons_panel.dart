import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
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
            width: 2.w,
            color: Theme.of(context).colors.walletHeaderDivider,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          //ANCHOR - Receive Button
          Expanded(
            child: WalletTabHeaderButton(
              svgAssetName: Svgs.walletReceive,
              radius: BorderRadius.only(bottomLeft: Radius.circular(20.r)),
              label: context.loc.receive,
              onPressed: () => Navigator.of(context).pushNamed(
                TransactionMenuScreen.routeName,
                arguments: TransactionType.receive,
              ),
            ),
          ),
          VerticalDivider(
            thickness: 2.w,
            width: 1,
            color: Theme.of(context).colors.walletHeaderDivider,
          ),
          //ANCHOR - Send Button
          Expanded(
            child: WalletTabHeaderButton(
              svgAssetName: Svgs.walletSend,
              label: context.loc.send,
              onPressed: () => Navigator.of(context).pushNamed(
                TransactionMenuScreen.routeName,
                arguments: TransactionType.send,
              ),
            ),
          ),
          VerticalDivider(
            thickness: 2.w,
            width: 2.w,
            color: Theme.of(context).colors.walletHeaderDivider,
          ),
          //ANCHOR - Scan Button
          Expanded(
            child: WalletTabHeaderButton(
              svgAssetName: Svgs.walletScan,
              label: context.loc.scan,
              radius: BorderRadius.only(bottomRight: Radius.circular(20.r)),
              onPressed: () => Navigator.of(context).pushNamed(
                QrScannerScreen.routeName,
                arguments: QrScannerScreenArguments(
                    parseAction: QrScannerParseAction.parse),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
