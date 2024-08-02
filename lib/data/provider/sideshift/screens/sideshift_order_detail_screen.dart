import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/sideshift/models/sideshift.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aqua/utils/utils.dart';
import 'package:intl/intl.dart';

class SideshiftOrderDetailScreen extends HookConsumerWidget {
  static const routeName = '/sideshiftOrderDetailScreen';

  const SideshiftOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ModalRoute.of(context)?.settings.arguments
        as SideshiftOrderStatusResponse;

    // fetch fresh status
    final orderStatus = ref.watch(orderStatusProvider(order.id ?? ''));
    return orderStatus.when(
      data: (data) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    top: 31.h,
                    left: 16.w,
                    right: 16.w,
                    bottom: 71.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ANCHOR - Order status
                      _SideshiftOrderDetailHeaderWidget(order: order),
                      SizedBox(height: 10.h),

                      // ANCHOR - Order details
                      _SideshiftOrderDetailsWidget(order: order),
                      SizedBox(height: 12.h),

                      // ANCHOR - Deposit & settle amount
                      _ShiftOrderAmountDetailWidget(
                          title: context.loc.sideshiftOrderDepositAmount,
                          amount: order.depositAmount),
                      _ShiftOrderAmountDetailWidget(
                          title: context.loc.sideshiftOrderSettleAmount,
                          amount: order.settleAmount),

                      SizedBox(height: 12.h),

                      DashedDivider(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),

                      SizedBox(height: 36.h),

                      // ANCHOR - Copyable shift id
                      _SideshiftOrderDetailCopyableItemWidget(
                        title: context.loc.receiveAssetScreenShiftId,
                        text: order.id.toString(),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: order.id.toString()));
                          Future.microtask(() => context.showAquaSnackbar(
                              context.loc.sideshiftOrderIdCopiedSnackbar));
                        },
                      ),
                      SizedBox(height: 24.h),

                      // ANCHOR - Copyable deposit address
                      _SideshiftOrderDetailCopyableItemWidget(
                        title: context.loc.sideshiftDepositAddress,
                        text: order.depositAddress ?? '-',
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: order.depositAddress ?? ''));
                          Future.microtask(() => context.showAquaSnackbar(
                              context
                                  .loc.sideshiftDepositAddressCopiedSnackbar));
                        },
                      ),
                      SizedBox(height: 24.h),

                      // ANCHOR - Copyable settle address
                      _SideshiftOrderDetailCopyableItemWidget(
                        title: context.loc.sideshiftSettleAddress,
                        text: order.settleAddress ?? '-',
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: order.settleAddress ?? ''));
                          Future.microtask(() => context.showAquaSnackbar(
                              context
                                  .loc.sideshiftSettleAddressCopiedSnackbar));
                        },
                      ),
                      SizedBox(height: 48.h),

                      // ANCHOR - Customer service link
                      Center(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.secondary,
                          ),
                          onPressed: () => ref.read(urlLauncherProvider).open(
                              'https://sideshift.ai/orders/${order.id.toString()}?openSupport=true'),
                          child: Text(context.loc.sideshiftCustomerService),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
    );
  }
}

class _SideshiftOrderDetailHeaderWidget extends StatelessWidget {
  const _SideshiftOrderDetailHeaderWidget({
    required this.order,
  });

  final SideshiftOrderStatusResponse order;

  @override
  Widget build(BuildContext context) {
    final orderStatusStr =
        order.status != null ? order.status!.localizedString(context) : '-';

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ANCHOR - Shift status
          Text("${context.loc.status}: $orderStatusStr",
              style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}

class _SideshiftOrderDetailsWidget extends StatelessWidget {
  const _SideshiftOrderDetailsWidget({
    required this.order,
  });

  final SideshiftOrderStatusResponse order;

  @override
  Widget build(BuildContext context) {
    final createAtStr = order.createdAt != null
        ? DateFormat(
                'MMM d, yyyy \'${context.loc.assetTransactionDetailsTimeAt}\' HH:mm')
            .format(DateTime.fromMicrosecondsSinceEpoch(
                order.createdAt!.microsecondsSinceEpoch))
        : '-';
    final expiresAtStr = order.expiresAt != null
        ? DateFormat(
                'MMM d, yyyy \'${context.loc.assetTransactionDetailsTimeAt}\' HH:mm')
            .format(DateTime.fromMicrosecondsSinceEpoch(
                order.expiresAt!.microsecondsSinceEpoch))
        : '-';

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ANCHOR - Created row
          Row(children: [
            Text("${context.loc.sideshiftOrderCreatedAt} $createAtStr",
                style: Theme.of(context).textTheme.bodyMedium),
          ]),
          SizedBox(height: 10.h),

          // ANCHOR - Expiry row
          Row(children: [
            Text("${context.loc.sideshiftOrderExpiresAt} $expiresAtStr",
                style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ],
      ),
    );
  }
}

class _ShiftOrderAmountDetailWidget extends StatelessWidget {
  const _ShiftOrderAmountDetailWidget({
    required this.title,
    required this.amount,
  });

  final String? amount;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          Expanded(
            child: Text(
              amount ?? '-',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideshiftOrderDetailCopyableItemWidget extends StatelessWidget {
  const _SideshiftOrderDetailCopyableItemWidget({
    required this.title,
    required this.text,
    required this.onPressed,
  });

  final String title;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 20.0),
            InkWell(
              onTap: onPressed,
              child: SvgPicture.asset(
                Svgs.copy,
                width: 17.w,
                height: 17.w,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface, BlendMode.srcIn),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
