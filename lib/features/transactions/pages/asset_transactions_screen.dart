import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/address_list/address_list.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/features/transactions/transactions.dart';
import 'package:coin_cz/utils/utils.dart';

class AssetTransactionsScreen extends HookConsumerWidget {
  const AssetTransactionsScreen({super.key, required this.asset});

  static const routeName = '/assetTransactionsScreen';
  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      sideswapWebsocketProvider,
      (_, __) {},
    );
    ref.listen(
      swapAssetsProvider,
      (_, __) {},
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: SizedBox(
        height: context.adaptiveDouble(mobile: 115.0, smallMobile: 85.0),
        child: BottomAppBar(
          height: context.adaptiveDouble(mobile: 115.0, smallMobile: 85.0),
          elevation: 8.0,
          color: Theme.of(context).colors.colorScheme.surface,
          child: TransactionMenuBottomBar(asset: asset),
        ),
      ),
      appBar: AquaAppBar(
        title: asset.isLBTC ? context.loc.layer2Bitcoin : asset.name,
        showBackButton: true,
        showActionButton: true,
        actionButtonAsset: Svgs.history,
        backgroundColor:
            Theme.of(context).colors.transactionAppBarBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        iconOutlineColor: Theme.of(context).colors.appBarIconOutlineColorAlt,
        iconBackgroundColor:
            Theme.of(context).colors.appBarIconBackgroundColorAlt,
        iconForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        onActionButtonPressed: () {
          context.push(
            AddressListScreen.routeName,
            extra: AddressListArgs(
              networkType:
                  asset.isBTC ? NetworkType.bitcoin : NetworkType.liquid,
              asset: asset,
            ),
          );
        },
      ),
      body: Stack(
        children: [
          //ANCHOR - List
          Container(
            margin: EdgeInsets.only(
              top: context.adaptiveDouble(mobile: 290.0, smallMobile: 190.0),
            ),
            child: AssetTransactions(
              asset: asset,
            ),
          ),
          // ANCHOR - Header
          AssetDetailsHeader(asset: asset),
          // ANCHOR - Gradient Overlay
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height * .1,
                decoration: BoxDecoration(
                  gradient: Theme.of(context).getFadeGradient(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
