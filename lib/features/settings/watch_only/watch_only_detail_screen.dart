import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/receive/widgets/receive_asset_copy_address_button.dart';
import 'package:aqua/features/settings/watch_only/watch_only.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WatchOnlyDetailScreen extends StatelessWidget {
  static const routeName = '/watchOnlyDetailScreen';

  const WatchOnlyDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet =
        ModalRoute.of(context)!.settings.arguments as WatchOnlyWallet;

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.watchOnlyScreenTitle,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: BoxShadowCard(
            elevation: 4.h,
            color:
                Theme.of(context).colors.addressFieldContainerBackgroundColor,
            borderRadius: BorderRadius.circular(12.r),
            bordered: true,
            borderColor: Theme.of(context).colors.cardOutlineColor,
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  Text(
                    context.loc
                        .watchOnlyWalletTitle(wallet.networkType.displayName),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 28.h),
                  WatchOnlyQrCode(
                    exportData: wallet.exportData,
                  ),
                  SizedBox(height: 36.h),
                  CopyAddressButton(
                    address: wallet.exportData,
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

class WatchOnlyQrCode extends StatelessWidget {
  final String exportData;

  const WatchOnlyQrCode({
    super.key,
    required this.exportData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: exportData,
            version: QrVersions.auto,
            size: 300.r,
          ),
        ],
      ),
    );
  }
}
