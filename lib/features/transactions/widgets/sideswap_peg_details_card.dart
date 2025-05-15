import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SideswapPegDetailsCard extends HookConsumerWidget {
  const SideswapPegDetailsCard(
      {super.key, required this.uiModel, required this.arguments});

  final AssetTransactionDetailsUiModel uiModel;
  final TransactionUiModel arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TransactionDbModel? dbTransaction =
        useMemoized(() => arguments.dbTransaction);

    if (dbTransaction == null || !dbTransaction.isPeg) {
      return const SizedBox.shrink();
    }

    // peg status
    useEffect(() {
      ref.read(pegStatusProvider.notifier).requestPegStatus(
            orderId: dbTransaction.serviceOrderId!,
            isPegIn: dbTransaction.isPegIn,
          );
      return () {};
    }, [dbTransaction]);

    final consolidatedStatus = ref.watch(pegStatusProvider).consolidatedStatus;

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
              dbTransaction.isPegIn
                  ? context.loc.sideswapPegInDescription
                  : context.loc.sideswapPegOutDescription,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24.0),
            //ANCHOR - Service Order Id
            LabelCopyableTextView(
              label: context.loc.orderId,
              value: dbTransaction.serviceOrderId ?? '-',
            ),
            const SizedBox(height: 18.0),
            //ANCHOR - Deposit Address
            if (dbTransaction.serviceAddress != null &&
                dbTransaction.serviceAddress!.isNotEmpty)
              LabelCopyableTextView(
                label: context.loc.depositAddress,
                value: dbTransaction.serviceAddress!,
              ),
            const SizedBox(height: 18.0),
            //ANCHOR - Status
            TransactionDetailsStatusChip(
              color: _getStatusColor(consolidatedStatus?.state),
              text: _getStatusText(context, consolidatedStatus),
            ),
            const SizedBox(height: 18.0),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(PegTxState? state) {
    switch (state) {
      case PegTxState.done:
        return AquaColors.aquaGreen;
      case PegTxState.processing:
      case PegTxState.detected:
        return AquaColors.gray;
      case PegTxState.insufficientAmount:
        return AquaColors.vermillion;
      case null:
        return AquaColors.gray;
    }
  }

  String _getStatusText(BuildContext context, ConsolidatedPegStatus? status) {
    switch (status?.state) {
      case PegTxState.done:
        return context.loc.assetTransactionDetailSuccess;
      case PegTxState.processing:
        return context.loc.assetTransactionDetailInProgressTxs(
            status?.detectedConfs, status?.totalConfs);
      case PegTxState.detected:
        return context.loc.assetTransactionDetailInProgress;
      case PegTxState.insufficientAmount:
        return context.loc.assetTransactionDetailInsufficientAmount;
      case null:
        return context.loc.assetTransactionDetailInProgress;
    }
  }
}
