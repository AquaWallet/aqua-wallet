import 'dart:convert';

import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/features/boltz/boltz.dart' hide SwapType;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:aqua/utils/extensions/date_time_ext.dart';
import 'package:boltz_dart/boltz_dart.dart';

class BoltzSwapDetailScreen extends HookConsumerWidget {
  static const routeName = '/boltzSwapDetailScreen';

  const BoltzSwapDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapData =
        ModalRoute.of(context)?.settings.arguments as BoltzSwapDbModel;

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
              _buildSwapDetails(swapData, ref, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwapDetails(
      BoltzSwapDbModel swapData, WidgetRef ref, BuildContext context) {
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
          _BoltzDetailHeaderWidget(
              status: swapData.lastKnownStatus ?? BoltzSwapStatus.created),
          SizedBox(height: 24.h),

          _BoltzDetailWidget(
              title: context.loc.boltzSwapCreatedAt,
              subtitle: swapData.createdAt?.yMMMdHm() ?? '--'),
          SizedBox(height: 6.h),
          _BoltzDetailWidget(
              title: context.loc.boltzInvoiceAmount,
              subtitle: '${swapData.amountFromInvoice}'),
          SizedBox(height: 6.h),
          _BoltzDetailWidget(
              title: context.loc.boltzTimeoutBlockHeight,
              subtitle: '${swapData.locktime}'),

          SizedBox(height: 24.h),
          DashedDivider(
            color: Theme.of(context).colorScheme.onBackground,
          ),
          SizedBox(height: 40.h),

          _CopyButton(data: swapData.toJson().toString()),
          SizedBox(height: 24.h),

          if (swapData.kind == SwapType.submarine)
            FutureBuilder<BoltzRefundData?>(
              future: ref
                  .read(boltzSubmarineSwapProvider.notifier)
                  .getRefundData(swapData),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return _RefundButton(refundData: snapshot.data);
                }
              },
            ),
          if (swapData.kind == SwapType.submarine) SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.boltzId, value: swapData.boltzId),
          SizedBox(height: 24.h),

          LabelCopyableTextView(
              label: context.loc.lightningInvoice, value: swapData.invoice),
          SizedBox(height: 24.h),

          if (swapData.kind == SwapType.submarine) ...[
            LabelCopyableTextView(
                label: context.loc.boltzRefundTx,
                value: swapData.refundTxId ?? 'N/A'),
            SizedBox(height: 24.h),
          ],

          if (swapData.kind == SwapType.reverse) ...[
            LabelCopyableTextView(
                label: context.loc.boltzClaimTx,
                value: swapData.claimTxId ?? 'N/A'),
            SizedBox(height: 24.h),
          ],
        ],
      ),
    );
  }
}

class _BoltzDetailHeaderWidget extends StatelessWidget {
  const _BoltzDetailHeaderWidget({
    required this.status,
  });

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
    required this.title,
    required this.subtitle,
  });

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
