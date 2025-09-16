import 'package:coin_cz/common/utils/encode_query_component.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/boltz/boltz.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/transactions/transactions.dart';
import 'package:coin_cz/utils/extensions/context_ext.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class BoltzReverseSwapDetailsCard extends HookConsumerWidget {
  const BoltzReverseSwapDetailsCard({
    super.key,
    required this.uiModel,
  });

  final AssetTransactionDetailsUiModel uiModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapDataFuture = ref
        .watch(boltzStorageProvider.notifier)
        .getReverseSwapDbModelByTxId(uiModel.dbTransaction?.txhash ?? '');

    return FutureBuilder<BoltzSwapDbModel?>(
      future: swapDataFuture,
      builder: (context, snapshot) {
        final swapData = snapshot.data;
        if (swapData == null) {
          return const SizedBox.shrink();
        }

        final boltzFee = BoltzFees.totalFeesReverse(swapData.invoice);

        final swapStatus =
            ref.watch(boltzSwapStatusProvider(swapData.boltzId)).when(
                  data: (data) => data.status,
                  loading: () => swapData.lastKnownStatus,
                  error: (_, __) => swapData.lastKnownStatus,
                );

        return BoxShadowCard(
          color: Theme.of(context).colors.altScreenSurface,
          bordered: true,
          borderColor: Theme.of(context).colors.cardOutlineColor,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: double.maxFinite,
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //ANCHOR - Title
                Text(
                  context.loc.boltzDescription,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 24.0),
                //ANCHOR - Transaction Id
                LabelCopyableTextView(
                  label: context.loc.boltzId,
                  value: swapData.boltzId,
                ),
                const SizedBox(height: 18.0),
                //ANCHOR - Transaction Fee
                Row(
                  children: [
                    TransactionDetailsDataItem(
                      title: context.loc.totalFees,
                      value: '$boltzFee sats',
                    ),
                  ],
                ),
                const SizedBox(height: 18.0),
                //ANCHOR - Address
                LabelCopyableTextView(
                  label: context.loc.address,
                  value: uiModel.dbTransaction?.receiveAddress ?? "",
                ),
                const SizedBox(height: 24.0),
                //ANCHOR - Status
                TransactionDetailsStatusChip(
                  color: switch (swapStatus) {
                    _ when (swapStatus!.needsRefund) => AquaColors.vermillion,
                    _ when (swapStatus == BoltzSwapStatus.invoiceSettled) =>
                      AquaColors.aquaGreen,
                    _ => AquaColors.gray,
                  },
                  text: switch (swapStatus) {
                    _ when (swapStatus.needsRefund) =>
                      context.loc.boltzSendStatusFailed,
                    _ when (swapStatus.isSuccess) =>
                      context.loc.boltzSendStatusSuccess,
                    _ when (swapStatus.isPending) =>
                      context.loc.boltzSendStatusPending,
                    _ => context.loc.boltzSendUnknownStatus,
                  },
                ),

                const SizedBox(height: 18.0),
                //ANCHOR - Boltz Support
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
                    path: boltzSupportEmail,
                    query: encodeQueryParameters(<String, String>{
                      'subject': 'Aqua - Boltz Swap Id: ${swapData.boltzId}',
                      'cc': aquaSupportEmail,
                    }),
                  )),
                  child: Text(context.loc.boltzSupportEmail),
                ),
                const SizedBox(height: 18.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
