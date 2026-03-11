import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:ui_components/ui_components.dart';

import 'address_list.dart';

class AddressListScreen extends HookConsumerWidget {
  const AddressListScreen({super.key, required this.args});
  final AddressListArgs args;

  static const routeName = '/addressList';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkType = args.networkType;

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

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        title: context.loc.addresses,
        showBackButton: true,
        // TODO: Fix swap orders page not fetching data first to uncomment this
        // actions: [
        //   args.asset.isUsdtLiquid || args.asset.isLayerTwo
        //       ? AquaIcon.history(
        //           color: context.aquaColors.textPrimary,
        //           onTap: () {
        //             if (args.asset.isUsdtLiquid) {
        //               context.push(SwapOrdersScreen.routeName);
        //             } else if (args.asset.isLayerTwo) {
        //               context.push(BoltzSwapsScreen.routeName);
        //             }
        //           },
        //         )
        //       : const SizedBox.shrink(),
        // ],
        colors: context.aquaColors,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AquaTabBar(
              height: 36,
              tabs: [context.loc.used, context.loc.unused],
              onTabChanged: (index) => showUsedAddresses.value = index == 0,
              initialIndex: showUsedAddresses.value ? 0 : 1,
              selectedColor: context.aquaColors.surfacePrimary,
            ),
            const SizedBox(height: 26.0),
            AquaSearchField(
              controller: searchController,
              onChanged: (value) {
                ref
                    .read(addressListProvider(networkType).notifier)
                    .search(value);
              },
            ),
            const SizedBox(height: 24.0),
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListView.separated(
                          itemCount: filteredAddresses.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 1),
                          itemBuilder: (context, index) => AddressListItem(
                            address: filteredAddresses[index],
                            isUsed: showUsedAddresses.value,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
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
    return AquaCard(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //ANCHOR: TX Count
            _TxCounter(address: address),
            const SizedBox(width: 16.0),
            //ANCHOR: Address, Amount, Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //ANCHOR: Address
                  AquaColoredText(
                    text: address.address ?? '',
                    style: AquaTypography.body2SemiBold.copyWith(
                        fontFamily: UiFontFamily.robotoMono,
                        color: context.aquaColors.textPrimary),
                    colorType: ColoredTextEnum.coloredIntegers,
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Container(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.copyToClipboard(address.address ?? ''),
                  child: AquaIcon.copy(
                    size: 18,
                    color: context.aquaColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TxCounter extends StatelessWidget {
  const _TxCounter({
    required this.address,
  });

  final GdkPreviousAddress address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.0,
      height: 40.0,
      decoration: BoxDecoration(
        color: context.aquaColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: context.aquaColors.surfaceBorderPrimary,
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: AquaText.caption1SemiBold(
        text: '${address.txCount ?? 0} TX',
        color: context.aquaColors.textSecondary,
      ),
    );
  }
}
