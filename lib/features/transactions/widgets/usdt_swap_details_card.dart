import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:url_launcher/url_launcher.dart';

class USDtSwapDetailsCard extends HookConsumerWidget {
  const USDtSwapDetailsCard(
      {super.key, required this.uiModel, required this.arguments});

  final AssetTransactionDetailsUiModel uiModel;
  final TransactionUiModel arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TransactionDbModel? dbTransaction =
        useMemoized(() => arguments.dbTransaction);

    if (dbTransaction == null ||
        !dbTransaction.isUSDtSwap ||
        dbTransaction.serviceOrderId == null) {
      // if no order id, then no swap details card
      return const SizedBox.shrink();
    }

    final swapOrder = ref
        .watch(swapDBOrderProvider(dbTransaction.serviceOrderId!))
        .valueOrNull;

    if (swapOrder == null) {
      // if no order, then no swap details card
      return const SizedBox.shrink();
    }

    final status = ref
        .watch(
          swapStatusProvider(SwapStatusParams(
              orderId: dbTransaction.serviceOrderId!,
              serviceType: swapOrder.serviceType)),
        )
        .valueOrNull;

    return BoxShadowCard(
      color: Theme.of(context).colors.altScreenSurface,
      bordered: true,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //ANCHOR - Title
            Text(
              context.loc.usdtSwapPoweredBy(swapOrder.serviceType.displayName),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24.0),
            //ANCHOR - Transaction Id
            LabelCopyableTextView(
              label: context.loc.orderId,
              value: dbTransaction.serviceOrderId ?? '-',
            ),
            const SizedBox(height: 18.0),
            //ANCHOR - Deposit Address
            LabelCopyableTextView(
              label: context.loc.depositAddress,
              value: swapOrder.depositAddress,
            ),
            const SizedBox(height: 18.0),
            // ANCHOR - Settle Address
            LabelCopyableTextView(
              label: context.loc.settleAddress,
              value: swapOrder.settleAddress,
            ),
            const SizedBox(height: 18.0),
            //ANCHOR - Status
            TransactionDetailsStatusChip(
              color: _getStatusColor(status?.orderStatus),
              text: _getStatusText(context, status?.orderStatus),
            ),
            const SizedBox(height: 18.0),

            //ANCHOR - Support
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colors.onBackground,
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
                textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 12.0,
                    ),
              ),
              onPressed: () => launchUrl(Uri(
                scheme: 'mailto',
                path: aquaSupportEmail,
                query: encodeQueryParameters(<String, String>{
                  'subject':
                      'USDt Swap - ${swapOrder.serviceType.displayName} Swap Id: ${swapOrder.orderId}',
                }),
              )),
              child: Text(context.loc.getHelpSupportScreenTitle),
            ),
            const SizedBox(height: 18.0),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SwapOrderStatus? status) {
    switch (status) {
      case SwapOrderStatus.completed:
        return AquaColors.aquaGreen;
      case SwapOrderStatus.processing:
      case SwapOrderStatus.exchanging:
      case SwapOrderStatus.sending:
      case SwapOrderStatus.waiting:
        return AquaColors.gray;
      case SwapOrderStatus.failed:
      case SwapOrderStatus.refunding:
      case SwapOrderStatus.refunded:
      case SwapOrderStatus.expired:
        return AquaColors.vermillion;
      case SwapOrderStatus.unknown:
      case null:
        return AquaColors.gray;
    }
  }

  // will display "USDt Swap {status}"
  String _getStatusText(BuildContext context, SwapOrderStatus? status) {
    final usdtSwapPrefix = context.loc.usdtSwap;
    switch (status) {
      case SwapOrderStatus.completed:
        return '$usdtSwapPrefix ${context.loc.success}';
      case SwapOrderStatus.processing:
      case SwapOrderStatus.exchanging:
      case SwapOrderStatus.sending:
      case SwapOrderStatus.waiting:
        return '$usdtSwapPrefix ${context.loc.inProgress}';
      case SwapOrderStatus.failed:
        return '$usdtSwapPrefix ${context.loc.failed}';
      case SwapOrderStatus.refunding:
        return '$usdtSwapPrefix ${context.loc.refunding}';
      case SwapOrderStatus.refunded:
        return '$usdtSwapPrefix ${context.loc.refunded}';
      case SwapOrderStatus.expired:
        return '$usdtSwapPrefix ${context.loc.expired}';
      case SwapOrderStatus.unknown:
      case null:
        return '$usdtSwapPrefix ${context.loc.inProgress}';
    }
  }
}
