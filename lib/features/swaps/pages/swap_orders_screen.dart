import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';

class SwapOrdersScreen extends ConsumerWidget {
  static const routeName = '/swapOrdersScreen';

  const SwapOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    return PopScope(
      onPopInvoked: (_) async {
        logger.debug('[Navigation] onPopInvoked in SwapOrdersScreen called');
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AquaAppBar(
          title: context.loc.usdtSwapOrders,
          showBackButton: true,
          showActionButton: false,
          backgroundColor: darkMode
              ? Colors.transparent
              : Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colors.onBackground,
        ),
        body: const _SwapOrdersList(),
      ),
    );
  }
}

class _SwapOrdersList extends HookConsumerWidget {
  const _SwapOrdersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedOrdersAsync = ref.watch(swapStorageProvider);

    return cachedOrdersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              context.loc.usdtSwapOrderListEmptyState,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return ListView.separated(
          itemCount: items.length,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(left: 28.0, right: 28.0, top: 20.0),
          separatorBuilder: (context, index) => const SizedBox(height: 16.0),
          itemBuilder: (_, index) => _SwapOrderListItem(items[index]),
        );
      },
    );
  }
}

class _SwapOrderListItem extends HookConsumerWidget {
  const _SwapOrderListItem(this.order);

  final SwapOrderDbModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    final orderStatusStr = order.status.toLocalizedString(context);

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.0),
      bordered: !darkMode,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: () {
            context.push(
              SwapOrderDetailScreen.routeName,
              extra: order,
            );
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            height: 160.0,
            padding:
                const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(children: [
                          Text(
                            "${context.loc.status}: $orderStatusStr",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Expanded(
                            child: Visibility(
                              visible: order.settleAmount != null &&
                                  order.settleAmount!.isNotEmpty &&
                                  order.settleAmount != '0',
                              child: Text(
                                order.settleAmount ?? '',
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10.0),
                        Row(children: [
                          Text(
                            "${context.loc.orderId}: ${order.orderId}",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontSize: 13.0,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ]),
                        const SizedBox(height: 7.0),
                        Row(children: [
                          Text(
                            "${context.loc.createdAt}: ${order.createdAt.yMMMd()}",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontSize: 13.0,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ]),
                        const SizedBox(height: 7.0),
                        Row(children: [
                          Text(
                            "${context.loc.expiresAt}: ${order.expiresAt?.yMMMd() ?? '-'}",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontSize: 13.0,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ]),
                        const SizedBox(height: 7.0),
                        Row(children: [
                          Text(
                            "${context.loc.service}: ${order.serviceType.displayName}",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontSize: 13.0,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
