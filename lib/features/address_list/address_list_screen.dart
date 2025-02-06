import 'package:aqua/common/widgets/tab_switch_view.dart';
import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/boltz/screens/boltz_swaps_screen.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/pages/swap_orders_screen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import 'address_list.dart';

class AddressListScreen extends HookConsumerWidget {
  const AddressListScreen({super.key, required this.args});
  final AddressListArgs args;

  static const routeName = '/addressList';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkType = args.networkType;
    final asset = args.asset;

    final addressListsAsync = ref.watch(addressListProvider(networkType));
    final refresherKey = useMemoized(UniqueKey.new);
    final controller = useRef(RefreshController(initialRefresh: false)).value;
    final showUsedAddresses = useState(true);
    final searchController = useTextEditingController();

    final filteredAddresses = useMemoized(() {
      return addressListsAsync.maybeWhen(
        data: (addressLists) => ref
            .read(addressListProvider(networkType).notifier)
            .getFilteredAddresses(showUsedAddresses.value),
        orElse: () => [],
      );
    }, [addressListsAsync, showUsedAddresses.value, searchController.text]);

    final onRefresh = useCallback(() async {
      try {
        await ref
            .read(addressListProvider(networkType).notifier)
            .refreshAddresses();
        controller.refreshCompleted();
      } catch (e) {
        controller.refreshFailed();
      }
    });

    final onLoading = useCallback(() async {
      try {
        final result = await ref
            .read(addressListProvider(networkType).notifier)
            .loadMoreAddresses();
        if (result) {
          controller.loadComplete();
        } else {
          controller.loadNoData();
        }
      } catch (e) {
        controller.loadFailed();
      }
    });

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.addressHistory,
        showBackButton: true,
        showActionButton: asset.isUsdtLiquid || asset.isLayerTwo,
        actionButtonAsset: Svgs.history,
        onActionButtonPressed: () {
          if (asset.isUsdtLiquid) {
            context.push(SwapOrdersScreen.routeName);
          } else if (asset.isLayerTwo) {
            context.push(BoltzSwapsScreen.routeName);
          }
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: context.loc.searchHistory,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onChanged: (value) {
                ref
                    .read(addressListProvider(networkType).notifier)
                    .search(value);
              },
            ),
          ),
          const SizedBox(height: 12.0),
          TabSwitchView(
            labels: [
              context.loc.usedAddresses,
              context.loc.addressHistoryUnused
            ],
            onChange: (index) => showUsedAddresses.value = index == 0,
            initialIndex: showUsedAddresses.value ? 0 : 1,
          ),
          const SizedBox(height: 12.0),
          Expanded(
            child: addressListsAsync.when(
              loading: () => const AddressListSkeleton(),
              error: (error, stack) => Center(child: Text(error.toString())),
              data: (addressLists) {
                if (filteredAddresses.isEmpty) {
                  return const AddressHistoryEmptyView();
                } else {
                  return SmartRefresher(
                    key: refresherKey,
                    enablePullDown: true,
                    enablePullUp: addressLists.hasMore,
                    controller: controller,
                    onRefresh: onRefresh,
                    onLoading: onLoading,
                    child: ListView.separated(
                      itemCount: filteredAddresses.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16.0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 20.0),
                      itemBuilder: (context, index) => AddressListItem(
                        address: filteredAddresses[index],
                        isUsed: showUsedAddresses.value,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddressListItem extends HookConsumerWidget {
  final GdkPreviousAddress address;
  final bool isUsed;

  const AddressListItem({
    super.key,
    required this.address,
    required this.isUsed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailLabelStyle =
        useMemoized(() => Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey[500],
            ));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR: TX Count
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${address.txCount ?? 0}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'TX Count',
                  style: detailLabelStyle,
                ),
              ],
            ),
            const SizedBox(width: 16.0),
            //ANCHOR: Address, Amount, Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //ANCHOR: Address
                  CopyableTextView(
                    text: address.address ?? '',
                    margin: const EdgeInsetsDirectional.only(
                      top: 0.0,
                      bottom: 0.0,
                      start: 0.0,
                      end: 12.0,
                    ),
                  ),
                  // TODO: Uncomment this block when logic is implemented:
                  //   1. Date of last tx
                  //   2. Total amount of txs in address

                  // if (isUsed) ...[
                  //   SizedBox(height: 8.0),
                  //   //ANCHOR: Amount + Date
                  //   Row(
                  //     children: [
                  //       Expanded(
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             Text(
                  //               'Received',
                  //               style: detailLabelStyle,
                  //             ),
                  //             Text('Feb 11, 2020', style: detailLabelStyle),
                  //           ],
                  //         ),
                  //       ),
                  //       Expanded(
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.end,
                  //           children: [
                  //             Text('0.07898800', style: detailLabelStyle),
                  //             Text(
                  //               'Bitcoin',
                  //               style: detailLabelStyle,
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //       SizedBox(width: 40.0),
                  //     ],
                  //   ),
                  // ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
