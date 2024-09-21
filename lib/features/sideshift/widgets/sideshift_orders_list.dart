import 'dart:async';

import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SideShiftOrdersList extends HookConsumerWidget {
  const SideShiftOrdersList({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedOrdersAsync = ref.watch(sideshiftStorageProvider);
    final cachedOrders = cachedOrdersAsync.asData?.value ?? [];

    // orderStatusProvider opens a stream for each order status update, so
    // refresh the cachedOrders list every 5 seconds
    useEffect(() {
      Timer.periodic(const Duration(seconds: 5), (_) {
        ref.invalidate(sideshiftStorageProvider);
      });

      for (final order in cachedOrders) {
        logger.d("[Sideshift] Update: ${order.status} - ShiftId: ${order.id}");
      }

      final shiftIds =
          cachedOrders.map((order) => order.orderId).cast<String>().toList();
      for (final shiftId in shiftIds) {
        ref.watch(orderStatusProvider(shiftId));
      }
      logger.d("[Sideshift] watching shifts : ${shiftIds.length}");

      // stream cancellation happens in SideShiftOrdersScreen
      return null;
    }, [cachedOrders.length]);

    return cachedOrdersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              context.loc.sideshiftOrderListEmptyState,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return Container(
          padding: EdgeInsets.only(top: 40.h),
          child: ListView.separated(
            primary: false,
            itemCount: items.length,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.only(left: 28.w, right: 28.w, top: 20.h),
            separatorBuilder: (context, index) => SizedBox(height: 16.h),
            itemBuilder: (_, index) => _SideShiftOrderListItem(items[index]),
          ),
        );
      },
    );
  }
}

class _SideShiftOrderListItem extends HookConsumerWidget {
  const _SideShiftOrderListItem(this.order);

  final SideshiftOrderDbModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final orderStatusStr =
        order.status != null ? order.status!.localizedString(context) : '-';

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.r),
      bordered: !darkMode,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(
              SideshiftOrderDetailScreen.routeName,
              arguments: order,
            );
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: 160.h,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(children: [
                          //ANCHOR - Status
                          Text(
                            "${context.loc.status}: $orderStatusStr",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          //ANCHOR - Amount
                          Expanded(
                            child: Text(
                              order.settleAmount ?? '',
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ]),
                        SizedBox(height: 10.h),

                        // ANCHOR - Shift Id row
                        Row(children: [
                          Text(
                            "${context.loc.receiveAssetScreenShiftId}: ${order.id.toString()}",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontSize: 13.sp,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ]),
                        SizedBox(height: 7.h),

                        // ANCHOR - Created row
                        Row(children: [
                          Text(
                            "${context.loc.sideshiftOrderCreatedAt}: ${order.createdAt?.yMMMd() ?? '-'}",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontSize: 13.sp,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ]),
                        SizedBox(height: 7.h),

                        // ANCHOR - Expiry row
                        Row(children: [
                          Text(
                            "${context.loc.sideshiftOrderExpiresAt}: ${order.expiresAt?.yMMMd() ?? '-'}",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontSize: 13.sp,
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
