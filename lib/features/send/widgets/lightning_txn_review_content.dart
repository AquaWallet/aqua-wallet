import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:intl/intl.dart';

class LightningTxnReviewContent extends ConsumerWidget {
  const LightningTxnReviewContent(this.args, {super.key});

  final SendAssetArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaction = ref.watch(sendAssetTxnProvider(args)).value;
    final input = ref.watch(sendAssetInputStateProvider(args)).value!;
    final isNotesEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.addNoteEnabled));

    return Column(
      children: [
        //ANCHOR - Send Review Card
        SendAssetReviewInfoCard(
          asset: input.asset,
          address: input.addressFieldText ?? '-',
          amount: input.amount.toString(),
        ),
        //ANCHOR - Aqua Fee Card
        ...?transaction?.maybeWhen(
          created: (t) => [
            const SizedBox(height: 22),
            _LightningTxnFeeCard(
              input: input,
              transaction: t.txReply,
            ),
            const SizedBox(height: 15),
            TransactionFeeBreakdownCard(
              args: args.toFeeStructureArgs(),
            ),
            const SizedBox(height: 15),
            const _OrderIdCard(),
          ],
          orElse: () => [
            const SizedBox(height: 22),
            const CircularProgressIndicator(),
          ],
        ),
        const SizedBox(height: 22),
        //ANCHOR - Add Note
        if (isNotesEnabled) ...{
          const AddNoteButton(),
        },
      ],
    );
  }
}

class _LightningTxnFeeCard extends ConsumerWidget {
  const _LightningTxnFeeCard({
    required this.input,
    required this.transaction,
  });

  final SendAssetInputState input;
  final GdkNewTransactionReply? transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = input.amount + (transaction?.fee ?? 0);
    final boltzOrder = ref.watch(boltzSubmarineSwapProvider);
    final fee = boltzOrder != null
        ? BoltzFees.totalFeesSubmarine(boltzOrder.invoice)
        : 0;

    return BoxShadowCard(
      color: context.colors.altScreenSurface,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - "Send To" plus address
            Text(
              style: context.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w500),
              context.loc.sendTo,
            ),
            const SizedBox(height: 8),
            Text(context.loc.lightningInvoice),
            // ANCHOR - Fee breakdown
            const SizedBox(height: 15),
            _TxnAmountItem(
              title: context.loc.amount,
              value: input.amountFieldText ?? '',
            ),
            const SizedBox(height: 5),
            _TxnAmountItem(
              title: context.loc.fee,
              value: fee.toString(),
            ),
            const SizedBox(height: 3),
            Divider(color: context.colors.divider),
            const SizedBox(height: 3),
            _TxnAmountItem(
              title: context.loc.total,
              value: total.toString(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TxnAmountItem extends StatelessWidget {
  const _TxnAmountItem({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  String _formatAmount(String value) {
    final amount = int.tryParse(value);
    if (amount == null) return value;
    return '${NumberFormat.decimalPattern().format(amount)} sats';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          title,
        ),
        Text(_formatAmount(value))
      ],
    );
  }
}

class _OrderIdCard extends ConsumerWidget {
  const _OrderIdCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(boltzSubmarineSwapProvider);
    if (order == null) {
      return const SizedBox.shrink();
    }

    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    return BoxShadowCard(
      color: context.colors.altScreenSurface,
      bordered: !darkMode,
      borderRadius: BorderRadius.circular(12),
      borderColor: context.colors.cardOutlineColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        //ANCHOR - Order ID
        child: LabelCopyableTextView(
          label: context.loc.boltzOrderId,
          value: order.id,
        ),
      ),
    );
  }
}
