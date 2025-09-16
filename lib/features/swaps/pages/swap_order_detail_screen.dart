import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class SwapOrderDetailScreen extends HookConsumerWidget {
  static const routeName = '/swapOrderDetailScreen';

  const SwapOrderDetailScreen({super.key, required this.order});
  final SwapOrderDbModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsyncValue = ref.watch(
      swapStatusProvider(SwapStatusParams.fromOrder(order)),
    );

    final depositAmountStr = double.parse(order.depositAmount) == 0
        ? '-'
        : order.depositAmount.toString();
    final settleAmountStr = double.parse(order.settleAmount ?? "0") == 0
        ? '-'
        : order.settleAmount.toString();

    return Scaffold(
      body: SafeArea(
        child: statusAsyncValue.when(
          data: (status) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => context.maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(
                    top: 31.0,
                    left: 16.0,
                    right: 16.0,
                    bottom: 71.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SwapOrderDetailHeaderWidget(
                        order: order,
                        status: status.orderStatus ?? SwapOrderStatus.unknown,
                      ),
                      const SizedBox(height: 10.0),
                      _SwapOrderDetailsWidget(order: order),
                      const SizedBox(height: 12.0),
                      _SwapOrderAmountDetailWidget(
                        title: context.loc.depositAmount,
                        amount: depositAmountStr,
                      ),
                      _SwapOrderAmountDetailWidget(
                        title: context.loc.settleAmount,
                        amount: settleAmountStr,
                      ),
                      const SizedBox(height: 12.0),
                      DashedDivider(
                        color: Theme.of(context).colors.onBackground,
                      ),
                      const SizedBox(height: 36.0),
                      _SwapOrderDetailCopyableItemWidget(
                        title: context.loc.orderId,
                        text: order.orderId,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: order.orderId));
                          context.showAquaSnackbar(
                              context.loc.swapIdCopiedSnackbar);
                        },
                      ),
                      const SizedBox(height: 24.0),
                      _SwapOrderDetailCopyableItemWidget(
                        title: context.loc.depositAddress,
                        text: order.depositAddress,
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: order.depositAddress));
                          context.showAquaSnackbar(
                              context.loc.depositAddressCopied);
                        },
                      ),
                      const SizedBox(height: 24.0),
                      _SwapOrderDetailCopyableItemWidget(
                        title: context.loc.settleAddress,
                        text: order.settleAddress,
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: order.settleAddress));
                          context.showAquaSnackbar(
                              context.loc.settleAddressCopied);
                        },
                      ),
                      const SizedBox(height: 48.0),
                      Center(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.secondary,
                          ),
                          onPressed: () => ref.read(urlLauncherProvider).open(
                              order.serviceType
                                  .serviceUrl(orderId: order.orderId)),
                          child: Text(context.loc.customerService),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _SwapOrderDetailHeaderWidget extends StatelessWidget {
  const _SwapOrderDetailHeaderWidget({
    required this.order,
    required this.status,
  });

  final SwapOrderDbModel order;
  final SwapOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final orderStatusStr = status.toLocalizedString(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${context.loc.status}: $orderStatusStr",
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10.0),
          Text("${context.loc.service}: ${order.serviceType.displayName}",
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SwapOrderDetailsWidget extends StatelessWidget {
  const _SwapOrderDetailsWidget({
    required this.order,
  });

  final SwapOrderDbModel order;

  @override
  Widget build(BuildContext context) {
    final createAtStr = DateFormat(
            'MMM d, yyyy \'${context.loc.assetTransactionDetailsTimeAt}\' HH:mm')
        .format(order.createdAt);
    final expiresAtStr = order.expiresAt != null
        ? DateFormat(
                'MMM d, yyyy \'${context.loc.assetTransactionDetailsTimeAt}\' HH:mm')
            .format(order.expiresAt!)
        : '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${context.loc.createdAt} $createAtStr",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10.0),
          Text("${context.loc.expiresAt} $expiresAtStr",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10.0),
          Text("${context.loc.from} ${order.fromAsset}",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10.0),
          Text("${context.loc.to} ${order.toAsset}",
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SwapOrderAmountDetailWidget extends StatelessWidget {
  const _SwapOrderAmountDetailWidget({
    required this.title,
    required this.amount,
  });

  final String amount;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4.0),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _SwapOrderDetailCopyableItemWidget extends StatelessWidget {
  const _SwapOrderDetailCopyableItemWidget({
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
                width: 17.0,
                height: 17.0,
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
