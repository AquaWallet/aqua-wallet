import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_list/address_list.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';

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
        height: 115.0,
        child: BottomAppBar(
          height: 115.0,
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
            margin: const EdgeInsets.only(top: 290.0),
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
