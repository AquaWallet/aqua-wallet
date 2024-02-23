import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/sideshift/screens/sideshift_orders_screen.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';

class AssetTransactionsScreen extends StatefulHookConsumerWidget {
  const AssetTransactionsScreen({super.key});

  static const routeName = '/assetTransactionsScreen';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => State();
}

class State extends ConsumerState<AssetTransactionsScreen> {
  @override
  Widget build(BuildContext context) {
    final asset = ModalRoute.of(context)?.settings.arguments as Asset;

    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: SizedBox(
        height: 115.h,
        child: BottomAppBar(
          height: 115.h,
          elevation: 8.h,
          color: Theme.of(context).colors.colorScheme.surface,
          child: TransactionMenuBottomBar(asset: asset),
        ),
      ),
      appBar: AquaAppBar(
        title: asset.name == 'Liquid Bitcoin'
            ? AppLocalizations.of(context)!.layer2Bitcoin
            : asset.name,
        showBackButton: true,
        showActionButton: asset
            .isUsdtLiquid, // For now only show the action button for USDT to show the sideshift orders screen
        actionButtonAsset: Svgs.history,
        backgroundColor:
            Theme.of(context).colors.transactionAppBarBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        iconOutlineColor: Theme.of(context).colors.appBarIconOutlineColorAlt,
        iconBackgroundColor:
            Theme.of(context).colors.appBarIconBackgroundColorAlt,
        iconForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        onActionButtonPressed: () => Navigator.of(context).pushNamed(
          SideShiftOrdersScreen.routeName,
        ),
      ),
      body: Stack(
        children: [
          //ANCHOR - List
          Container(
            margin: EdgeInsets.only(top: 290.h),
            child: const AssetTransactions(),
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
