import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class SwapOrdersList extends HookConsumerWidget {
  const SwapOrdersList({
    super.key,
    required this.orders,
    required this.hasMore,
    required this.onLoadMore,
  });

  final List<SwapOrderDbModel> orders;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();

    useEffect(() {
      void onScroll() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent * 0.8) {
          if (hasMore) {
            onLoadMore();
          }
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [hasMore]);

    if (orders.isEmpty) {
      return const SwapOrdersListEmptyView();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: ListView.separated(
        controller: scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: orders.length + (hasMore ? 1 : 0),
        padding: EdgeInsets.zero,
        separatorBuilder: (context, index) => const SizedBox(height: 1),
        itemBuilder: (_, index) {
          if (hasMore && index == orders.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return _SwapOrderListItem(order: orders[index]);
        },
      ),
    );
  }
}

class _SwapOrderListItem extends ConsumerWidget {
  const _SwapOrderListItem({required this.order});

  final SwapOrderDbModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderStatusStr = order.status.toLocalizedString(context);
    final settleAmount = order.settleAmount != null &&
            order.settleAmount!.isNotEmpty &&
            order.settleAmount != '0'
        ? order.settleAmount!
        : '';

    return AquaListItem(
      title: order.orderId,
      subtitle: order.serviceType.displayName,
      titleTrailing: settleAmount,
      subtitleTrailing: orderStatusStr,
      iconTrailing: AquaIcon.chevronForward(
        size: 18,
        color: context.aquaColors.textSecondary,
      ),
      colors: context.aquaColors,
      onTap: () => context.push(
        SwapOrderDetailScreen.routeName,
        extra: order,
      ),
    );
  }
}
