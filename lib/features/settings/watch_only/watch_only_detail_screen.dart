import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/data/provider/network_frontend.dart';
import 'package:coin_cz/features/receive/widgets/receive_asset_copy_address_button.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/wallet/models/subaccount.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WatchOnlyDetailScreen extends StatelessWidget {
  static const routeName = '/watchOnlyDetailScreen';

  const WatchOnlyDetailScreen({super.key, required this.wallet});
  final Subaccount wallet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.watchOnlyScreenTitle,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: BoxShadowCard(
            elevation: 4.0,
            color:
                Theme.of(context).colors.addressFieldContainerBackgroundColor,
            borderRadius: BorderRadius.circular(12.0),
            bordered: true,
            borderColor: Theme.of(context).colors.cardOutlineColor,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    context.loc
                        .watchOnlyWalletTitle(wallet.networkType.displayName),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 28.0),
                  WatchOnlyQrCode(
                    exportData: wallet.exportData,
                  ),
                  const SizedBox(height: 36.0),
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
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: exportData,
            version: QrVersions.auto,
            size: 300.0,
          ),
        ],
      ),
    );
  }
}
