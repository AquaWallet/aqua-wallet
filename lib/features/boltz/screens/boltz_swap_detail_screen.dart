import 'dart:convert';

import 'package:coin_cz/common/widgets/aqua_elevated_button.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/boltz/boltz.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/extensions/context_ext.dart';
import 'package:coin_cz/utils/extensions/date_time_ext.dart';
import 'package:boltz_dart/boltz_dart.dart';

class BoltzSwapDetailScreen extends HookConsumerWidget {
  static const routeName = '/boltzSwapDetailScreen';

  const BoltzSwapDetailScreen({super.key, required this.swapData});

  final BoltzSwapDbModel swapData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20.0),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () {
                    context.maybePop();
                  },
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
      padding: const EdgeInsets.only(
        top: 31.0,
        left: 16.0,
        right: 16.0,
        bottom: 71.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ANCHOR - Order status
          _BoltzDetailHeaderWidget(
              status: swapData.lastKnownStatus ?? BoltzSwapStatus.created),
          const SizedBox(height: 24.0),

          _BoltzDetailWidget(
              title: context.loc.createdAt,
              subtitle: swapData.createdAt?.yMMMdHm() ?? '--'),
          const SizedBox(height: 6.0),
          _BoltzDetailWidget(
              title: context.loc.boltzInvoiceAmount,
              subtitle: '${swapData.amountFromInvoice}'),
          const SizedBox(height: 6.0),
          _BoltzDetailWidget(
              title: context.loc.boltzTimeoutBlockHeight,
              subtitle: '${swapData.locktime}'),

          const SizedBox(height: 24.0),
          DashedDivider(
            color: Theme.of(context).colors.onBackground,
          ),
          const SizedBox(height: 40.0),

          _CopyButton(data: swapData.toJson().toString()),
          const SizedBox(height: 24.0),

          if (swapData.kind == SwapType.submarine) ...{
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
            const SizedBox(height: 24)
          },

          if (swapData.kind == SwapType.reverse &&
              swapData.claimTxId == null) ...{
            _ClaimButton(swapDbModel: swapData),
            const SizedBox(height: 24),
          },

          LabelCopyableTextView(
              label: context.loc.boltzId, value: swapData.boltzId),
          const SizedBox(height: 24.0),

          LabelCopyableTextView(
              label: context.loc.lightningInvoice, value: swapData.invoice),
          const SizedBox(height: 24.0),

          if (swapData.kind == SwapType.submarine) ...[
            LabelCopyableTextView(
                label: context.loc.boltzRefundTx,
                value: swapData.refundTxId ?? 'N/A'),
            const SizedBox(height: 24.0),
          ],

          if (swapData.kind == SwapType.reverse) ...[
            LabelCopyableTextView(
                label: context.loc.boltzClaimTx,
                value: swapData.claimTxId ?? 'N/A'),
            const SizedBox(height: 24.0),
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
      padding: const EdgeInsets.only(bottom: 14.0),
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
      padding: const EdgeInsets.only(bottom: 20.0),
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

class _ClaimButton extends ConsumerWidget {
  const _ClaimButton({required this.swapDbModel});

  final BoltzSwapDbModel swapDbModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: AquaElevatedButton(
        onPressed: () async {
          final swap = await ref
              .read(boltzStorageProvider.notifier)
              .getLbtcLnV2SwapById(swapDbModel.boltzId);

          if (swap != null) {
            ref.read(boltzSwapSettlementServiceProvider).claim(swap);
          }
        },
        child: Text(context.loc.boltzClaimSwap),
      ),
    );
  }
}
