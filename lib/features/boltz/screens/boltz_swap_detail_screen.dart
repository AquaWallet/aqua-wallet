import 'dart:convert';

import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:aqua/utils/extensions/date_time_ext.dart';

class BoltzSwapDetailScreen extends HookConsumerWidget {
  static const routeName = '/boltzSwapDetailScreen';

  const BoltzSwapDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapData = ModalRoute.of(context)?.settings.arguments;

    bool isReverseSwap = swapData is BoltzReverseSwapData;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
              if (isReverseSwap) _buildReverseSwapDetails(swapData, context),
              if (!isReverseSwap)
                _buildNormalSwapDetails(
                    swapData as BoltzSwapData, ref, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReverseSwapDetails(
      BoltzReverseSwapData swapData, BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 31.h,
        left: 16.w,
        right: 16.w,
        bottom: 71.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ANCHOR - Order status
          _BoltzDetailHeaderWidget(status: swapData.swapStatus),
          SizedBox(height: 24.h),

          _BoltzDetailWidget(
              title: context.loc.boltzSwapCreatedAt,
              subtitle: swapData.created?.yMMMdHm() ?? '--'),
          SizedBox(height: 6.h),
          _BoltzDetailWidget(
              title: context.loc.boltzInvoiceAmount,
              subtitle: '${swapData.request.invoiceAmount}'),
          SizedBox(height: 6.h),
          _BoltzDetailWidget(
              title: context.loc.boltzOnchainAmount,
              subtitle: '${swapData.response.onchainAmount}'),
          SizedBox(height: 6.h),
          _BoltzDetailWidget(
              title: context.loc.boltzTotalFees,
              subtitle:
                  '${BoltzService.calculateTotalServiceFeesReverse(swapData)}'),
          SizedBox(height: 6.h),
          _BoltzDetailWidget(
              title: context.loc.boltzTimeoutBlockHeight,
              subtitle: '${swapData.response.timeoutBlockHeight}'),

          SizedBox(height: 24.h),
          DashedDivider(
            color: Theme.of(context).colorScheme.onBackground,
          ),
          SizedBox(height: 40.h),

          _CopyButton(data: swapData.toJson().toString()),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzId, value: swapData.response.id),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.lightningInvoice,
              value: swapData.response.invoice),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzPreimage,
              value: swapData.secureData.preimageHex ?? '-'),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzPreimageHash,
              value: swapData.request.preimageHash),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzLockupAddress,
              value: swapData.response.lockupAddress),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzClaimPublicKey,
              value: swapData.request.claimPublicKey),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzRedeemScript,
              value: swapData.response.redeemScript),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzFallbackAddress,
              value: '${swapData.request.address ?? 'N/A'})'),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzClaimTx,
              value: swapData.claimTx ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildNormalSwapDetails(
      BoltzSwapData swapData, WidgetRef ref, BuildContext context) {
    final refundData = ref.read(boltzSwapRefundDataProvider(swapData));

    return Container(
      padding: EdgeInsets.only(
        top: 31.h,
        left: 16.w,
        right: 16.w,
        bottom: 71.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ANCHOR - Order status
          _BoltzDetailHeaderWidget(status: swapData.swapStatus),
          SizedBox(height: 24.h),

          _BoltzDetailWidget(
              title: context.loc.boltzSwapCreatedAt,
              subtitle: swapData.created?.yMMMdHm() ?? '--'),
          SizedBox(height: 6.h),
          _BoltzDetailWidget(
              title: context.loc.boltzInvoiceAmount,
              subtitle:
                  '${BoltzService.getAmountFromLightningInvoice(swapData.request.invoice)}'),
          SizedBox(height: 6.h),
          _BoltzDetailWidget(
              title: context.loc.boltzExpectedAmount,
              subtitle: '${swapData.response.expectedAmount}'),
          SizedBox(height: 6.h),
          _BoltzDetailWidget(
              title: context.loc.boltzTotalFees,
              subtitle:
                  '${BoltzService.calculateTotalServiceFeesNormalSwap(swapData)}'),
          SizedBox(height: 6.h),
          _BoltzDetailWidget(
              title: context.loc.boltzTimeoutBlockHeight,
              subtitle: '${swapData.response.timeoutBlockHeight}'),

          SizedBox(height: 24.h),
          DashedDivider(
            color: Theme.of(context).colorScheme.onBackground,
          ),
          SizedBox(height: 40.h),

          _RefundButton(refundData: refundData),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzId, value: swapData.response.id),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.address, value: swapData.response.address),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.lightningInvoice,
              value: swapData.request.invoice),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.bip21, value: swapData.response.bip21),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzRefundPrivateKey,
              value: swapData.secureData.privateKeyHex),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzRefundPublicKey,
              value: swapData.request.refundPublicKey),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzRedeemScript,
              value: swapData.response.redeemScript),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzOnchainTx,
              value: swapData.onchainTxHash ?? 'N/A'),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzRefundTx,
              value: swapData.refundTx ?? 'N/A'),
        ],
      ),
    );
  }
}

class _BoltzDetailHeaderWidget extends StatelessWidget {
  const _BoltzDetailHeaderWidget({
    Key? key,
    required this.status,
  }) : super(key: key);

  final BoltzSwapStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ANCHOR - Swap status
          Text("${context.loc.status}: ${status.value}",
              style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}

class _BoltzDetailWidget extends StatelessWidget {
  const _BoltzDetailWidget({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        children: [
          Text(
            title,
          ),
          Expanded(
            child: Text(
              subtitle ?? '-',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final String data;

  const _CopyButton({required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AquaElevatedButton(
        onPressed: () {
          context.copyToClipboard(data);
        },
        child: Text(context.loc.boltzCopySwapData),
      ),
    );
  }
}

class _RefundButton extends StatelessWidget {
  final BoltzRefundData? refundData;

  const _RefundButton({required this.refundData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AquaElevatedButton(
        onPressed: () {
          final jsonString = jsonEncode(refundData?.toJson());
          context.copyToClipboard(jsonString);
        },
        child: Text(context.loc.boltzCopyRefundData),
      ),
    );
  }
}
