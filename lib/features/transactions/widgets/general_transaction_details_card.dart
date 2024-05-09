import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';

class GeneralTransactionDetailsCard extends HookConsumerWidget {
  const GeneralTransactionDetailsCard({
    super.key,
    required this.uiModel,
  });

  final AssetTransactionDetailsUiModel uiModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as TransactionUiModel;

    return BoxShadowCard(
      color: Theme.of(context).colors.altScreenSurface,
      bordered: true,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...uiModel.map(
              swap: (item) => [
                TransactionDetailsDataItem(
                  title: context.loc.assetTransactionDetailsDelivered,
                  value: '${item.deliverAmount} ${item.deliverAssetTicker}',
                ),
                SizedBox(height: 18.h),
                TransactionDetailsDataItem(
                  title: context.loc.assetTransactionDetailsReceived,
                  value: '${item.receiveAmount} ${item.receiveAssetTicker}',
                ),
              ],
              redeposit: (item) => [
                if (!item.isConfidential) ...[
                  TransactionDetailsDataItem(
                    title: context.loc.assetTransactionsTotalAmount,
                    value: '${item.deliverAmount} ${item.deliverAssetTicker}',
                  ),
                  SizedBox(height: 18.h),
                ],
                TransactionDetailsDataItem(
                  title: context.loc.assetTransactionsNetworkFees,
                  value: '${item.feeAmount} ${item.feeAssetTicker}',
                ),
              ],
              send: (item) => [
                TransactionDetailsDataItem(
                  title: context.loc.assetTransactionsTotalAmount,
                  value: '${item.deliverAmount} ${item.deliverAssetTicker}',
                ),
                SizedBox(height: 18.h),
                TransactionDetailsDataItem(
                  title: context.loc.assetTransactionsNetworkFees,
                  value: '${item.feeAmount} ${item.feeAssetTicker}',
                ),
              ],
              receive: (item) => [
                TransactionDetailsDataItem(
                  title: context.loc.assetTransactionsTotalAmount,
                  value: '${item.receivedAmount} ${item.receivedAssetTicker}',
                ),
              ],
            ),
            SizedBox(height: 18.h),
            TransactionDetailsDataItem(
              title: context.loc.assetTransactionsDate,
              value: uiModel.date,
            ),
            SizedBox(height: 18.h),
            LabelCopyableTextView(
              label: context.loc.assetTransactionDetailsTransactionId,
              value: uiModel.transactionId,
            ),
            SizedBox(height: 18.h),
            ...uiModel.maybeMap(
              swap: (model) {
                if (model.dbTransaction?.serviceAddress?.isNotEmpty == true) {
                  return [
                    LabelCopyableTextView(
                      label: context.loc.assetTransactionDetailsDepositAddress,
                      value: model.dbTransaction!.serviceAddress!,
                    ),
                    SizedBox(height: 18.h),
                  ];
                }
                return [];
              },
              orElse: () => [],
            ),
            Center(
              child: TransactionDetailsStatusChip(
                color:
                    uiModel.isPending ? AquaColors.gray : AquaColors.aquaGreen,
                text: !uiModel.isPending
                    ? context.loc.assetTransactionDetailsConfirmed
                    : uiModel.isDeliverLiquid
                        ? context.loc.assetTransactionDetailsAccepted
                        : context.loc.assetTransactionDetailsPending,
              ),
            ),
            SizedBox(height: 18.h),
            Center(
              child: TransactionDetailsExplorerButtons(
                model: arguments,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
