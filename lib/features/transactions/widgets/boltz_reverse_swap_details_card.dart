import 'package:aqua/common/utils/encode_query_component.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:url_launcher/url_launcher.dart';

class BoltzReverseSwapDetailsCard extends HookConsumerWidget {
  const BoltzReverseSwapDetailsCard({
    super.key,
    required this.uiModel,
  });

  final AssetTransactionDetailsUiModel uiModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as TransactionUiModel;

    final swapData = ref
        .watch(boltzReverseSwapFromTxHashProvider(
            arguments.transaction.txhash ?? ''))
        .asData
        ?.value;

    if (swapData == null || swapData.response.id.isEmpty) {
      return const SizedBox.shrink();
    }

    final boltzFee = useMemoized(
      () => BoltzService.calculateTotalServiceFeesReverse(swapData),
      [swapData],
    );

    final swapStatus = ref
            .watch(boltzSwapStatusStreamProvider(SwapStatusRequest(
                id: swapData.response.id, forceNewStream: true)))
            .asData
            ?.value
            .status ??
        swapData.swapStatus;

    return BoxShadowCard(
      color: Theme.of(context).colors.altScreenSurface,
      bordered: true,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
            SizedBox(height: 24.h),
            //ANCHOR - Transaction Id
            LabelCopyableTextView(
              label: context.loc.sendAssetCompleteScreenBoltzIdLabel,
              value: swapData.response.id,
            ),
            SizedBox(height: 18.h),
            //ANCHOR - Transaction Fee
            Row(
              children: [
                TransactionDetailsDataItem(
                  title: context.loc.boltzServiceFee,
                  value: '$boltzFee sats',
                ),
              ],
            ),
            SizedBox(height: 18.h),
            //ANCHOR - Invoice
            LabelCopyableTextView(
              label: context.loc.lightningInvoice,
              value: swapData.response.invoice,
            ),
            SizedBox(height: 18.h),
            //ANCHOR - Address
            LabelCopyableTextView(
              label: context.loc.address,
              value: swapData.response.lockupAddress,
            ),
            SizedBox(height: 18.h),
            //ANCHOR - Status
            TransactionDetailsStatusChip(
              color: switch (swapStatus) {
                _ when (swapStatus.isFailed) => AquaColors.vermillion,
                _ when (swapStatus.isSuccess) => AquaColors.aquaGreen,
                _ => AquaColors.gray,
              },
              text: switch (swapStatus) {
                _ when (swapStatus.isFailed) =>
                  context.loc.boltzSendStatusFailed,
                _ when (swapStatus.isSuccess) =>
                  context.loc.boltzSendStatusSuccess,
                _ when (swapStatus.isPending) =>
                  context.loc.boltzSendStatusPending,
                _ => context.loc.boltzSendUnknownStatus,
              },
            ),

            SizedBox(height: 18.h),
            //ANCHOR - Boltz Support
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onBackground,
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.r,
                ),
                textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 12.sp,
                    ),
              ),
              onPressed: () => launchUrl(Uri(
                scheme: 'mailto',
                path: boltzSupportEmail,
                query: encodeQueryParameters(<String, String>{
                  'subject': 'Aqua - Boltz Swap Id: ${swapData.response.id}',
                  'cc': aquaSupportEmail,
                }),
              )),
              child: Text(context.loc.boltzSupportEmail),
            ),
          ],
        ),
      ),
    );
  }
}
